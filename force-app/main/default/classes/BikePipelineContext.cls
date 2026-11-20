public class BikePipelineContext {
    public Id bikeId;
    public String eventType;
    public String rawPayload;
    public Bike__c bikeRecord;
    public Boolean isRegistryClean = false;
    public String registryResponseMessage;
    public List<String> errors = new List<String>();

    // Seznam názvů tříd kroků, které zbývá v řetězci vykonat
    public List<String> remainingSteps = new List<String>();

    public BikePipelineContext() {}

    public BikePipelineContext(Bike_Service_Event__e evt) {
        this.bikeId = (Id) evt.Bike_Id__c;
        this.eventType = evt.Event_Type__c;
        this.rawPayload = evt.Payload_Json__c;
    }

    public Boolean hasErrors() {
        return !this.errors.isEmpty();
    }
}