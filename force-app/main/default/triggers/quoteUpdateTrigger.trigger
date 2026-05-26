//Automatically resets quote status to draft when editing approved quotes
trigger quoteUpdateTrigger on Quote (before update) {


    for (Quote newQuote: Trigger.new){
        Quote oldQuote = Trigger.oldMap.get(newQuote.Id); // gets previous Status

        if(oldQuote.Status == 'Approved'){ 
            newQuote.Status = 'Draft';
        }
    }
}