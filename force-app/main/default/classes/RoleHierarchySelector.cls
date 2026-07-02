public inherited sharing class RoleHierarchySelector {

    // Retrieves the Salesforce Role assigned to each user involved
    // in the deal-freeze authorization check.
    public static Map<Id, User> getUsersByIds(Set<Id> userIds) {
        if (userIds == null || userIds.isEmpty()) {
            return new Map<Id, User>();
        }

        return new Map<Id, User>([
            SELECT
                Id,
                UserRoleId
            FROM User
            WHERE Id IN :userIds
        ]);
    }

    // Retrieves role parent relationships used to determine whether
    // the current user's role is above the Opportunity owner's role.
    public static Map<Id, UserRole> getAllRoles() {
        return new Map<Id, UserRole>([
            SELECT
                Id,
                ParentRoleId
            FROM UserRole
        ]);
    }
}
 