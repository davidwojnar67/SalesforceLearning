public with sharing class BikeFlowActions {
    // Anotace, která z Apexu udělá klikací kostičku.
    // Category zajistí, že to ve Flow bude mít vlastní hezkou složku.
    @InvocableMethod(
        label='Odeslat kolo do API'
        description='Zařadí kolo do asynchronní fronty pro registraci'
        category='Bike Management'
    )
    public static void sendBikesToRegistry(List<Bike__c> bikes) {
        // I když Flow běží pro jeden záznam, platforma nám ho vždy pošle jako List (Bulkifikace).
        // My ten List rovnou předáme naší existující frontě.
        if (bikes != null && !bikes.isEmpty()) {
            System.enqueueJob(new BikeRegistryQueueable(bikes));
        }
    }
}