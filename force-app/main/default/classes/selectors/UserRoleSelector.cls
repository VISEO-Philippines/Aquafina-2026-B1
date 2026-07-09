/**
 * Selector for UserRole and User records used in role hierarchy traversal.
 * Queries role data without sharing enforcement to ensure the full hierarchy
 * is always visible, independent of the current user's access.
 */
public without sharing class UserRoleSelector {

    /**
     * Returns UserRole records for the given IDs with Id and ParentRoleId.
     * Used to iteratively walk the role hierarchy from a known set of roles
     * upward to the root, without loading the full org role tree.
     *
     * @param roleIds Set of UserRole IDs to fetch
     * @return List of UserRole records
     */
    public List<UserRole> getRolesByIds(Set<Id> roleIds) {
        return [
            SELECT Id, ParentRoleId
            FROM UserRole
            WHERE Id IN :roleIds
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
