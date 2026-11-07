import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import type { AppPermission } from '../../shared/types/user';
import { logActivity } from '../../shared/utils/activity-log';
import {
  createWorkerAccount,
  employeeCodeOwner,
  getManagedWorker,
  getWorkerUserId,
  grantPermissions,
  listActivePermissions,
  listManagedWorkers,
  revokePermissions,
  updateAuthUser,
  updateUserRow,
  updateWorkerProfileRow,
} from './workers.repo';
import type { ManagedWorkerView } from './workers.repo';
import type { CreateWorkerInput, UpdateWorkerInput } from './workers.schema';

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function notFound(): AppError {
  return new AppError(404, 'not_found', 'Karyawan tidak ditemukan');
}
function emailTaken(): AppError {
  return new AppError(409, 'email_taken', 'Email ini sudah terdaftar.');
}
function codeTaken(): AppError {
  return new AppError(409, 'employee_code_taken', 'Kode pegawai ini sudah dipakai.');
}
function weakPassword(): AppError {
  return new AppError(400, 'validation_error', 'Password terlalu lemah. Coba kombinasi yang lebih sulit ditebak.');
}

export async function listWorkersForManagement(
  env: Bindings,
): Promise<{ items: ManagedWorkerView[] }> {
  return { items: await listManagedWorkers(env) };
}

export async function createWorker(
  env: Bindings,
  actorUserId: string,
  input: CreateWorkerInput,
): Promise<ManagedWorkerView> {
  if (await employeeCodeOwner(env, input.employee_code)) throw codeTaken();

  const result = await createWorkerAccount(env, {
    email: input.email,
    password: input.password,
    fullName: input.full_name,
    phoneNumber: input.phone_number,
    employeeCode: input.employee_code,
    division: input.division,
    joinDate: input.join_date,
  });
  if (!result.ok) {
    if (result.reason === 'email_taken') throw emailTaken();
    if (result.reason === 'weak_password') throw weakPassword();
    throw codeTaken();
  }

  await logActivity(env, {
    userId: actorUserId,
    action: 'worker_create',
    entity: 'worker',
    entityId: result.workerId,
    metadata: { employee_code: input.employee_code, division: input.division },
  });

  const view = await getManagedWorker(env, result.workerId);
  if (!view) throw notFound();
  return view;
}

export async function updateWorker(
  env: Bindings,
  actorUserId: string,
  workerId: string,
  input: UpdateWorkerInput,
): Promise<ManagedWorkerView> {
  if (!UUID_RE.test(workerId)) throw notFound();
  const current = await getManagedWorker(env, workerId);
  const userId = await getWorkerUserId(env, workerId);
  if (!current || !userId) throw notFound();

  if (
    input.employee_code !== undefined &&
    input.employee_code.toLowerCase() !== current.employee_code.toLowerCase()
  ) {
    const owner = await employeeCodeOwner(env, input.employee_code);
    if (owner && owner !== workerId) throw codeTaken();
  }

  // Akun login lebih dulu: bila email/password ditolak, belum ada yang berubah.
  const authChange: { email?: string; password?: string } = {};
  if (input.email !== undefined && input.email !== current.email) authChange.email = input.email;
  if (input.password !== undefined) authChange.password = input.password;
  if (authChange.email !== undefined || authChange.password !== undefined) {
    const outcome = await updateAuthUser(env, userId, authChange);
    if (outcome === 'email_taken') throw emailTaken();
    if (outcome === 'weak_password') throw weakPassword();
  }

  const userPatch: Record<string, unknown> = {};
  if (input.full_name !== undefined) userPatch['full_name'] = input.full_name;
  if (input.phone_number !== undefined) userPatch['phone_number'] = input.phone_number;
  if (authChange.email !== undefined) userPatch['email'] = authChange.email;
  if (input.is_active !== undefined) userPatch['is_active'] = input.is_active;
  if (Object.keys(userPatch).length > 0) await updateUserRow(env, userId, userPatch);

  const profilePatch: Record<string, unknown> = {};
  if (input.employee_code !== undefined) profilePatch['employee_code'] = input.employee_code;
  if (input.division !== undefined) profilePatch['division'] = input.division;
  if (input.join_date !== undefined) profilePatch['join_date'] = input.join_date;
  if (Object.keys(profilePatch).length > 0) {
    if ((await updateWorkerProfileRow(env, workerId, profilePatch)) === 'employee_code_taken') {
      throw codeTaken();
    }
  }

  await logActivity(env, {
    userId: actorUserId,
    action: 'worker_update',
    entity: 'worker',
    entityId: workerId,
    // Nilai password tidak pernah dicatat.
    metadata: {
      fields: [...Object.keys(userPatch), ...Object.keys(profilePatch)],
      password_changed: input.password !== undefined,
    },
  });

  const view = await getManagedWorker(env, workerId);
  if (!view) throw notFound();
  return view;
}

export async function getWorkerPermissions(
  env: Bindings,
  workerId: string,
): Promise<{ permissions: AppPermission[] }> {
  if (!UUID_RE.test(workerId) || !(await getWorkerUserId(env, workerId))) throw notFound();
  return { permissions: await listActivePermissions(env, workerId) };
}

/** Hanya owner. Menerima daftar lengkap izin yang diinginkan dan menghitung selisihnya. */
export async function setWorkerPermissions(
  env: Bindings,
  ownerUserId: string,
  workerId: string,
  desired: AppPermission[],
): Promise<{ permissions: AppPermission[] }> {
  if (!UUID_RE.test(workerId) || !(await getWorkerUserId(env, workerId))) throw notFound();

  const wanted = new Set(desired);
  const current = new Set(await listActivePermissions(env, workerId));
  const toGrant = [...wanted].filter((p) => !current.has(p));
  const toRevoke = [...current].filter((p) => !wanted.has(p));

  await grantPermissions(env, workerId, toGrant, ownerUserId);
  await revokePermissions(env, workerId, toRevoke);

  if (toGrant.length > 0 || toRevoke.length > 0) {
    await logActivity(env, {
      userId: ownerUserId,
      action: 'worker_permissions_update',
      entity: 'worker',
      entityId: workerId,
      metadata: { granted: toGrant, revoked: toRevoke },
    });
  }
  return { permissions: await listActivePermissions(env, workerId) };
}
