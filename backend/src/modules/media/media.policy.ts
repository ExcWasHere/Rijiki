import type { AuthContextUser } from '../../shared/types/user';

// TODO saat modul orders/ratings jadi:
//   - 'documentations' (before/after/proof of delivery): customer pemilik order + worker yang di-assign
//   - 'testimonials': pemilik rating + pemegang izin manage_testimonials
export function canReadPrivate(ctx: AuthContextUser, key: string): boolean {
  if (ctx.ownerBypass) return true;

  const [folder, ownerId] = key.split('/');

  switch (folder) {
    case 'scans':
      return ownerId === ctx.user.id;
    case 'receipts':
      return ctx.user.role === 'worker' && ctx.permissions.includes('manage_finance');
    default:
      return false;
  }
}