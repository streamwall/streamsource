import { AccessControl } from 'accesscontrol';

// Define roles and permissions
export const accessControl = new AccessControl();

// Define permissions for each role
accessControl
  // Default role - read only
  .grant('default')
    .readAny('stream')
  
  // Editor role - can create and update
  .grant('editor')
    .extend('default')
    .createAny('stream')
    .updateAny('stream')
    .deleteAny('stream')
  
  // Admin role - full access
  .grant('admin')
    .extend('editor')
    .readAny('user')
    .createAny('user')
    .updateAny('user')
    .deleteAny('user');

// Helper function to check permissions
export function checkPermission(role: string, action: string, resource: string): boolean {
  const permission = accessControl.can(role)[action](resource);
  return permission.granted;
}