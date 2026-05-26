trigger TestAccountTrigger on Account (before insert) {
    for (Account a : Trigger.new) {
        if (a.Name == 'Pluto' ) {
          a.Name.addError('ERROR: Invalid Account Name');
        }
      }
}