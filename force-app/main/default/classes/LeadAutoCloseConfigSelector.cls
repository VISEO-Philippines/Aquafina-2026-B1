public inherited sharing class LeadAutoCloseConfigSelector {

    private static final String DEFAULT_CONFIG =
        'Default';

    private static final Integer DEFAULT_INACTIVITY_DAYS =
        60;

    // Retrieves the configured inactivity threshold used
    // by the Lead auto-close batch.
    public static Integer getInactivityDays() {

        Lead_Auto_Close_Config__mdt config =
            Lead_Auto_Close_Config__mdt.getInstance(
                DEFAULT_CONFIG
            );

        if (
            config == null ||
            config.Inactivity_Days__c == null
        ) {
            return DEFAULT_INACTIVITY_DAYS;
        }

        return Integer.valueOf(
            config.Inactivity_Days__c
        );
    }
}