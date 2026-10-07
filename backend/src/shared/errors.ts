export type AppErrorStatus = 400 | 401 | 403 | 404 | 409 | 413 | 415 | 429 | 500 | 502;

export class AppError extends Error {
  constructor(
    public readonly status: AppErrorStatus,
    public readonly code: string,
    message: string,
  ) {
    super(message);
    this.name = 'AppError';
  }
}