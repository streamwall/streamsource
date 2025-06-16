const { accessControl } = require('../../auth/authorization');

describe('Authorization - Access Control', () => {
  describe('Admin role', () => {
    it('should have all permissions for streams', () => {
      const adminPermissions = accessControl.can('admin');
      
      expect(adminPermissions.createAny('stream').granted).toBe(true);
      expect(adminPermissions.readAny('stream').granted).toBe(true);
      expect(adminPermissions.updateAny('stream').granted).toBe(true);
      expect(adminPermissions.deleteAny('stream').granted).toBe(true);
    });
  });

  describe('Editor role', () => {
    it('should have all permissions for streams', () => {
      const editorPermissions = accessControl.can('editor');
      
      expect(editorPermissions.createAny('stream').granted).toBe(true);
      expect(editorPermissions.readAny('stream').granted).toBe(true);
      expect(editorPermissions.updateAny('stream').granted).toBe(true);
      expect(editorPermissions.deleteAny('stream').granted).toBe(true);
    });
  });

  describe('Default role', () => {
    it('should only have read permission for streams', () => {
      const defaultPermissions = accessControl.can('default');
      
      expect(defaultPermissions.readAny('stream').granted).toBe(true);
      expect(defaultPermissions.createAny('stream').granted).toBe(false);
      expect(defaultPermissions.updateAny('stream').granted).toBe(false);
      expect(defaultPermissions.deleteAny('stream').granted).toBe(false);
    });
  });

  describe('Unknown role', () => {
    it('should have no permissions', () => {
      // AccessControl throws an error for unknown roles, so we need to catch it
      expect(() => accessControl.can('unknown').readAny('stream')).toThrow('Role not found');
    });
  });

  describe('Access Control configuration', () => {
    it('should be locked to prevent modifications', () => {
      expect(accessControl.isLocked).toBe(true);
    });

    it('should have exactly three roles defined', () => {
      const roles = accessControl.getRoles();
      expect(roles).toHaveLength(3);
      expect(roles).toContain('admin');
      expect(roles).toContain('editor');
      expect(roles).toContain('default');
    });

    it('should only have stream as a resource', () => {
      const resources = accessControl.getResources();
      expect(resources).toHaveLength(1);
      expect(resources).toContain('stream');
    });
  });
});