/**
 * Selector for UserRole and User records used in role hierarchy traversal.
 * Queries role data without sharing enforcement to ensure the full hierarchy
 * is always visible, independent of the current user's access.
 */
public without sharing class UserRoleSelector {

    /**
     * Returns all UserRole records in the org with Id and ParentRoleId.
     * Used to build an in-memory parent map for role hierarchy traversal.
     *
     * @return List of all UserRole records
     */
    public List<UserRole> getAllRoles() {
        return [
            SELECT Id, ParentRoleId
            FROM UserRole
        ];
    }

    /**
     * Returns User records for the given IDs with their assigned UserRoleId.
     *
     * @param userIds Set of User IDs to fetch
     * @return List of User records with Id and UserRoleId
     */
    public List<User> getUsersByIds(Set<Id> userIds) {
        return [
            SELECT Id, UserRoleId
            FROM User
            WHERE Id IN :userIds
        ];
    }
}
