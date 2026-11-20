public without sharing class BikePipelineFinalizer implements System.Finalizer {
    private BikePipelineContext ctx;
    private String stepName;

    public BikePipelineFinalizer(BikePipelineContext ctx, String stepName) {
        this.ctx = ctx;
        this.stepName = stepName;
    }

    public void execute(System.FinalizerContext finalizerCtx) {
        if (finalizerCtx.getResult() == ParentJobResult.SUCCESS) {
            System.debug('[FINALIZER] Krok ' + stepName + ' doběhl úspěšně.');
        } else {
            Exception ex = finalizerCtx.getException();
            System.debug(LoggingLevel.ERROR, '[FINALIZER - KRITICKÝ PÁD] Krok: ' + stepName +
                ' | BikeId: ' + ctx.bikeId +
                ' | Chyba: ' + (ex != null ? ex.getMessage() : 'Neznámá chyba'));
            // V produkci by zde šlo např. publikovat chybový Platform Event (Publish Immediately)
        }
    }
}