public with sharing class ActivateDeactivateUsers {
    public static void ActivateUsers(String nameToActivate1, String nameToActivate2) {

        User u1 = [SELECT Id, IsActive FROM User WHERE User.Name=:nameToActivate1 ];
        u1.IsActive = true;
        update u1;

        User u2 = [SELECT Id, IsActive FROM User WHERE User.Name=:nameToActivate2 ];
        u2.IsActive = true;
        update u2;

    }

    public static void DeactivateUsers(String nameToDeactivate1, String nameToDeactivate2) {

        User u1 = [SELECT Id, IsActive FROM User WHERE User.Name=:nameToDeactivate1 ];
        u1.IsActive = false;
        update u1;

        User u2 = [SELECT Id, IsActive FROM User WHERE User.Name=:nameToDeactivate2 ];
        u2.IsActive = false;
        update u2;

    }
}