# Team Friendship Hour — Tasks

## Phase 1: Project Setup
- [ ] Create repo `kypris/team-friendship-hour` on Forgejo
- [ ] Initialize with README, Containerfile, compose.yaml
- [ ] Set up basic CI workflow (.forgejo/workflows/ci.yaml)
- [ ] Verify local CI runs with `forgejo-runner exec`

## Phase 2: Data Layer
- [ ] Design TeamMember data definition (HtDD)
- [ ] Design Activity data definition (HtDD)  
- [ ] Design Cycle data definition (HtDD)
- [ ] Implement JSON file storage
- [ ] Write tests for data layer

## Phase 3: Core Logic
- [ ] Implement rotation logic (who's next, cycle reset)
- [ ] Implement add/remove team member
- [ ] Implement record activity
- [ ] Write tests for all logic functions (HtDF)

## Phase 4: API Layer
- [ ] Set up http-nu server skeleton
- [ ] Implement GET /api/team (list members)
- [ ] Implement POST /api/team (add member)
- [ ] Implement DELETE /api/team/:id (remove member)
- [ ] Implement GET /api/activities (list activities)
- [ ] Implement POST /api/activities (record activity)
- [ ] Implement GET /api/cycle (current cycle status)
- [ ] Write API integration tests

## Phase 5: Frontend
- [ ] Set up Datastar frontend
- [ ] Build main view (current cycle, quick-add form)
- [ ] Build team management view
- [ ] Build calendar view
- [ ] Build history view

## Phase 6: Deployment
- [ ] Finalize Containerfile (Red Hat best practices)
- [ ] Test container build and run locally
- [ ] Deploy to loving-kypris
- [ ] Verify production deployment

## Definition of Done
- All tests pass locally (`forgejo-runner exec`)
- CI passes on remote runner
- Container runs with rootless Podman
- UID 1001, GID 0, group-writable dirs
