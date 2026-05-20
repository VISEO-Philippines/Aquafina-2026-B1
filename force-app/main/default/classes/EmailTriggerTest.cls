@isTest
private class EmailTriggerTest {

    @isTest
    static void emailWithNoSubject() {
        Boolean isError = false;
        // test case where exception is expected
        try {
            EmailMessage eMsg = new EmailMessage(TextBody='Test Email Body');
            insert eMsg;
        } catch (Exception ex) {
            isError = true;
        }

        System.assert(isError, 'ERROR: Email must have subject.');

    }
}