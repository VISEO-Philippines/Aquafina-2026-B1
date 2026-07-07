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


    // Retrieves only the roles required for hierarchy traversal.
    // Avoids querying unrelated roles outside the current transaction scope.
    public static Map<Id, UserRole> getRolesByIds(
        Set<Id> roleIds
    ) {
        if (roleIds == null || roleIds.isEmpty()) {
            return new Map<Id, UserRole>();
        }

        return new Map<Id, UserRole>([
            SELECT
                Id,
                ParentRoleId
            FROM UserRole
            WHERE Id IN :roleIds
        ]);
    }
}