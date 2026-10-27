public class BikeServiceReminderScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        BikeServiceReminderBatch batch = new BikeServiceReminderBatch();
        Database.executeBatch(batch, 200);
    }
}