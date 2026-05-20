trigger quoteEmailSent on EmailMessage (before insert) {

    // Requires every email to have a subject
    for (EmailMessage emailMsg :Trigger.new){
        if (emailMsg.Subject == null){
            emailMsg.Name.addError('Please add a SUBJECT to your email');
        }
    }

}