export type UpdateState = {
    isUpdated: boolean,
    needsRestart: boolean,
    updates: {[number]: {name: string, version: string, repository: string}},
}

export type UpdateAdapter = {
    refreshRepositories: ((UpdateState) -> never) -> never,
    checkUpdates: ((UpdateState) -> never) -> never,
    upgrade: () -> never,
}
