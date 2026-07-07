public class RoleHierarchyService {

    // Checks whether the current user is above one Opportunity owner
    // in the configured Salesforce Role Hierarchy.
    public static Boolean isCurrentUserManagerOrHigher(
        Id opportunityOwnerId
    ) {
        if (opportunityOwnerId == null) {
            return false;
        }

        Set<Id> authorizedOwnerIds = getAuthorizedOwnerIds(
            new Set<Id>{ opportunityOwnerId }
        );

        return authorizedOwnerIds.contains(opportunityOwnerId);
    }


    // Identifies Opportunity owners whose manager hierarchy includes
    // the current user's Salesforce Role.
    public static Set<Id> getAuthorizedOwnerIds(
        Set<Id> opportunityOwnerIds
    ) {
        Set<Id> authorizedOwnerIds = new Set<Id>();

        if (
            opportunityOwnerIds == null ||
            opportunityOwnerIds.isEmpty()
        ) {
            return authorizedOwnerIds;
        }

        Id currentUserId = UserInfo.getUserId();

        Set<Id> userIds = new Set<Id>{ currentUserId };
        userIds.addAll(opportunityOwnerIds);


        Map<Id, User> usersById =
            RoleHierarchySelector.getUsersByIds(userIds);


        User currentUser =
            usersById.get(currentUserId);


        if (
            currentUser == null ||
            currentUser.UserRoleId == null
        ) {
            return authorizedOwnerIds;
        }


        Set<Id> roleIds =
            collectRelevantRoleIds(
                usersById,
                opportunityOwnerIds
            );


        Map<Id, UserRole> rolesById =
            RoleHierarchySelector.getRolesByIds(
                roleIds
            );


        for (Id opportunityOwnerId : opportunityOwnerIds) {

            User opportunityOwner =
                usersById.get(opportunityOwnerId);


            // The Opportunity owner and users in the same role
            // are not included in the manager exception.
            if (
                opportunityOwner == null ||
                opportunityOwner.UserRoleId == null ||
                opportunityOwnerId == currentUserId ||
                opportunityOwner.UserRoleId ==
                    currentUser.UserRoleId
            ) {
                continue;
            }


            Boolean isManagerOrHigher =
                isParentRole(
                    currentUser.UserRoleId,
                    opportunityOwner.UserRoleId,
                    rolesById
                );


            if (isManagerOrHigher) {
                authorizedOwnerIds.add(opportunityOwnerId);
            }
        }


        return authorizedOwnerIds;
    }


    // Collects only roles involved in the current authorization check.
    // Traverses from Opportunity owner roles upward through parents.
    private static Set<Id> collectRelevantRoleIds(
        Map<Id, User> usersById,
        Set<Id> opportunityOwnerIds
    ) {
        Set<Id> roleIds = new Set<Id>();


        User currentUser =
            usersById.get(UserInfo.getUserId());


        if (
            currentUser != null &&
            currentUser.UserRoleId != null
        ) {
            roleIds.add(currentUser.UserRoleId);
        }


        for (Id opportunityOwnerId : opportunityOwnerIds) {

            User opportunityOwner =
                usersById.get(opportunityOwnerId);


            if (
                opportunityOwner != null &&
                opportunityOwner.UserRoleId != null
            ) {
                roleIds.add(
                    opportunityOwner.UserRoleId
                );
            }
        }


        Set<Id> rolesToProcess =
            new Set<Id>(roleIds);


        while (!rolesToProcess.isEmpty()) {

            Map<Id, UserRole> roles =
                RoleHierarchySelector.getRolesByIds(
                    rolesToProcess
                );


            rolesToProcess.clear();


            for (UserRole roleRecord : roles.values()) {

                if (
                    roleRecord.ParentRoleId != null &&
                    !roleIds.contains(
                        roleRecord.ParentRoleId
                    )
                ) {
                    roleIds.add(
                        roleRecord.ParentRoleId
                    );

                    rolesToProcess.add(
                        roleRecord.ParentRoleId
                    );
                }
            }
        }


        return roleIds;
    }


    // Walks upward from the Opportunity owner's role to determine whether
    // the current user's role is one of its parent roles.
    private static Boolean isParentRole(
        Id currentUserRoleId,
        Id opportunityOwnerRoleId,
        Map<Id, UserRole> rolesById
    ) {
        Id parentRoleId =
            getParentRoleId(
                opportunityOwnerRoleId,
                rolesById
            );


        Set<Id> visitedRoleIds =
            new Set<Id>();


        while (
            parentRoleId != null &&
            !visitedRoleIds.contains(parentRoleId)
        ) {

            if (parentRoleId == currentUserRoleId) {
                return true;
            }


            visitedRoleIds.add(parentRoleId);


            parentRoleId =
                getParentRoleId(
                    parentRoleId,
                    rolesById
                );
        }


        return false;
    }


    // Retrieves the parent role safely while keeping hierarchy traversal
    // separate from the authorization decision.
    private static Id getParentRoleId(
        Id roleId,
        Map<Id, UserRole> rolesById
    ) {
        UserRole roleRecord =
            rolesById.get(roleId);


        return roleRecord == null
            ? null
            : roleRecord.ParentRoleId;
    }
}