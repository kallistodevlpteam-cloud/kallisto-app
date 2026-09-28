export class ServiceError extends Error {
  constructor(public readonly code: string, public readonly status: number = 400) {
    super(code);
  }
}
