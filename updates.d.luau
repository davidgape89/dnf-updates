export type UpdateState = {
    isUpdated: boolean,
    needsRestart: boolean,
    updates: {[number]: {name: string, version: string, status: string}},
}