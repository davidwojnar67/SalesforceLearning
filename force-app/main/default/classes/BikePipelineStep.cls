public abstract without sharing class BikePipelineStep implements Queueable {
    protected BikePipelineContext ctx;

    public void setContext(BikePipelineContext ctx) {
        this.ctx = ctx;
    }

    // Každý konkrétní krok implementuje pouze svou byznys logiku
    protected abstract void process();

    public void execute(QueueableContext qCtx) {
        // Apex trik, jak za běhu zjistit název konkrétní potomecké třídy (např. BikeValidationStep),
        // protože String.valueOf(instance) v Apexu vrací formát NazevTridy:[promenna=hodnota]
        String currentStepName = String.valueOf(this).substringBefore(':');

        // 1. Registrace Finalizeru pro odchycení i fatálních LimitException pádů
        System.attachFinalizer(new BikePipelineFinalizer(this.ctx, currentStepName));

        try {
            // 2. Vykonání konkrétního kroku pipeline
            process();
        } catch (Exception e) {
            this.ctx.errors.add(currentStepName + ': ' + e.getMessage());
            system.debug(LoggingLevel.ERROR, '[PIPELINE ERROR] ' + currentStepName + ': ' + e.getMessage());
        }

        // 3. Předání štafety dalšímu kroku (pokud nevznikla chyba)
        if (!this.ctx.hasErrors() && !this.ctx.remainingSteps.isEmpty()) {
            enqueueNextStep(this.ctx);
        } else if (this.ctx.hasErrors()) {
            System.debug(LoggingLevel.WARN, '[PIPELINE STOPPED] Chyby: ' + String.join(this.ctx.errors, '; '));
        } else {
            System.debug('[PIPELINE COMPLETED] Všechny kroky pro kolo ' + this.ctx.bikeId + ' dokončeny');
        }
    }

    public static Id enqueueNextStep(BikePipelineContext ctx) {
        if (ctx == null || ctx.remainingSteps == null || ctx.remainingSteps.isEmpty()) {
            return null;
        }

        // V unit testech Salesforce zakazuje řetězení Queueable z jiného běžícího Queueable.
        // Volání z Triggeru nebo přímo z testovací metody (System.isQueueable() == false) projde,
        // ale pokus o spuštění dalšího článku řetězce uvnitř běžícího Queueable v testu zastavíme.
        if (Test.isRunningTest() && system.isQueueable()) {
            System.debug('[PIPELINE TEST GUARD] Řetězení dalšího Queueable kroku v testu přeskočeno.');
            return null;
        }

        String nextClassName = ctx.remainingSteps.remove(0);
        Type stepType = Type.forName(nextClassName);

        if (stepType == null) {
            throw new BikeException('Neznámý krok pipeline: ' + nextClassName);
        }

        // dynamická instanciace dalšího kroku bez nutnosti mít v bázové třídě switch/if
        // na všechny budoucí kroky (dodržení Open/Closed principu).
        BikePipelineStep nextStep = (BikePipelineStep) stepType.newInstance();
        nextStep.setContext(ctx);

        // Ochrana pro unit testy: Test.stopTest() povolí spustit jen 1 úroveň Queueable
        if (Test.isRunningTest() && Limits.getQueueableJobs() >= Limits.getLimitQueueableJobs()) {
            return null;
        }

        return System.enqueueJob(nextStep);
    }
}