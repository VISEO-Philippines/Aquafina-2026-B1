public with sharing class OpportunityContactsController {
    @AuraEnabled(cacheable=true)
    public static Boolean hasPrimaryContactRole(String oppId) {
        List<OpportunityContactRole> oppContRole = [SELECT Id, OpportunityId, 
        IsPrimary FROM OpportunityContactRole WHERE OpportunityId = :oppId]; // add IsPrimary in WHERE clause
        
        for (OpportunityContactRole ocr: oppContRole){
            if (ocr.IsPrimary == true){
                return true;
            }
        }

        return false;
    }

    @AuraEnabled(cacheable=true)
    public static List<OpportunityContactRole> hasPrimaryContactRoleEmail(String oppId){
        List<OpportunityContactRole> oppContRole = [SELECT Id, OpportunityId, 
        IsPrimary, Contact.Email FROM OpportunityContactRole WHERE (OpportunityId = :oppId AND IsPrimary=true )];

        return oppContRole;
    }

    @AuraEnabled(cacheable=true)
    public static Boolean checkForPrimary(String oppId){

        Boolean ito2; //use meaningful names for variables

        List<OpportunityContactRole> oppContRole = [ 
            SELECT Id, IsPrimary
            FROM OpportunityContactRole
            WHERE (OpportunityId = :oppId AND IsPrimary = true)
            LIMIT 1
            ];

        if (!oppContRole.isEmpty() && oppContRole[0] != null){ // error if oppContRole null; //can use toast for fault handling sa LWC
            ito2 = true;
        } else {
            ito2 = false;
        }

        return ito2;
        
    }

    @AuraEnabled(cacheable=true)
    public static Boolean checkForPrimaryEmail(String oppId){

        Boolean ito;

        List<OpportunityContactRole> oppContRole = [ 
            SELECT Id, Contact.Name, IsPrimary
            FROM OpportunityContactRole
            WHERE (OpportunityId = :oppId AND Contact.Email != null AND IsPrimary = true)
            LIMIT 1
            ];

        if (oppContRole[0] != null){
            ito = true;
        } else {
            ito = false;
        }

        return ito;
        
    }
}