from datetime import date, timedelta


def _monday_of_this_week() -> date:
    today = date.today()
    return today - timedelta(days=today.weekday())


def _post(client, headers, name, sets, reps, weight, d=None):
    body = {"exerciseName": name, "sets": sets, "reps": reps, "weight": weight}
    if d is not None:
        body["workoutDate"] = d.isoformat()
    return client.post("/api/workouts", json=body, headers=headers)


def test_create_and_list_workout(client, new_user):
    res = _post(client, new_user["headers"], "벤치프레스", 3, 10, 60)
    assert res.status_code == 201
    created = res.json()
    assert created["exerciseName"] == "벤치프레스"
    assert created["userId"] == new_user["userId"]

    listed = client.get("/api/workouts", headers=new_user["headers"]).json()
    assert [w["id"] for w in listed] == [created["id"]]


def test_invalid_workout_payload_is_rejected(client, new_user):
    assert _post(client, new_user["headers"], "벤치프레스", 0, 10, 60).status_code == 422
    assert _post(client, new_user["headers"], "벤치프레스", 3, 0, 60).status_code == 422
    assert _post(client, new_user["headers"], "벤치프레스", 3, 10, -1).status_code == 422


def test_weekly_volume_is_sets_times_reps_times_weight(client, new_user):
    monday = _monday_of_this_week()
    _post(client, new_user["headers"], "벤치프레스", 3, 10, 60, monday)  # 1800
    _post(client, new_user["headers"], "스쿼트", 4, 8, 100, monday)  # 3200

    stats = client.get("/api/workouts/weekly-stats", headers=new_user["headers"]).json()
    assert stats["userId"] == new_user["userId"]
    assert stats["totalRecords"] == 2
    volumes = stats["weeklyVolumeByDay"]
    assert sum(volumes.values()) == 5000
    assert max(volumes.values()) == 5000


def test_weekly_volume_splits_by_day(client, new_user):
    monday = _monday_of_this_week()
    _post(client, new_user["headers"], "데드리프트", 3, 5, 100, monday)  # 1500
    _post(client, new_user["headers"], "OHP", 3, 10, 40, monday + timedelta(days=2))  # 1200

    volumes = client.get(
        "/api/workouts/weekly-stats", headers=new_user["headers"]
    ).json()["weeklyVolumeByDay"]
    non_zero = sorted(v for v in volumes.values() if v)
    assert non_zero == [1200, 1500]


def test_delete_workout_updates_volume(client, new_user):
    monday = _monday_of_this_week()
    keep = _post(client, new_user["headers"], "렛풀다운", 3, 10, 50, monday).json()
    drop = _post(client, new_user["headers"], "바벨로우", 3, 10, 40, monday).json()

    res = client.delete(f"/api/workouts/{drop['id']}", headers=new_user["headers"])
    assert res.status_code == 200
    assert res.json()["deletedId"] == drop["id"]

    stats = client.get("/api/workouts/weekly-stats", headers=new_user["headers"]).json()
    assert stats["totalRecords"] == 1
    assert sum(stats["weeklyVolumeByDay"].values()) == 1500
    ids = [w["id"] for w in client.get("/api/workouts", headers=new_user["headers"]).json()]
    assert ids == [keep["id"]]


def test_delete_missing_workout_returns_404(client, new_user):
    res = client.delete("/api/workouts/999999", headers=new_user["headers"])
    assert res.status_code == 404


def test_cannot_delete_other_users_workout(client, new_user, auth_headers):
    mine = _post(client, new_user["headers"], "벤치프레스", 3, 10, 60).json()
    res = client.delete(f"/api/workouts/{mine['id']}", headers=auth_headers)
    assert res.status_code == 404
    still = client.get("/api/workouts", headers=new_user["headers"]).json()
    assert len(still) == 1
