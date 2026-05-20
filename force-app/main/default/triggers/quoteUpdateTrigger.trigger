/**
 * @description       : 
 * @author            : timothy-james.guela@viseo.com
 * @group             : 
 * @last modified on  : 05-13-2026
 * @last modified by  : timothy-james.guela@viseo.com
**/
//Automatically resets quote status to draft when editing approved quotes
trigger quoteUpdateTrigger on Quote (before update) {

    for (Quote newQuote: Trigger.new){
        Quote oldQuote = Trigger.oldMap.get(newQuote.Id); // gets previous Status

        if(oldQuote.Status == 'Approved'){ 
            newQuote.Status = 'Draft';
        }
    }
}