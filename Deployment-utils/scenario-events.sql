CREATE TEMPORARY TABLE lookup (
	id int,
	event_type varchar(255)
);

INSERT INTO lookup (id, event_type) VALUES
	(0, 'SEARCH'),
	(1, 'EVALUATION_SCENARIO'),
	(2, 'ROUTE_TIMING'),
	(3, 'PROXY_TIMING'),
	(4, 'ADD_RESOURCES_TO_PROJECT'),
	(5, 'EXTRACT_MODEL'),
	(6, 'PERSIST_MODEL'),
	(7, 'TRANSFORM_PROMPT'),
	(8, 'ADD_CODE_CELL'),
	(9, 'RUN_SIMULATION'),
	(10, 'RUN_CALIBRATE'),
	(11, 'GITHUB_IMPORT'),
	(12, 'OPERATOR_DRILLDOWN_TIMING'),
	(13, 'TEST_TYPE');

SELECT to_timestamp(timestamp_millis / 1000)::timestamp AS date_in_UTC, timestamp_millis, users.name, lookup.event_type, project_id, value
FROM event
JOIN users ON event.user_id = users.id
JOIN lookup ON event.type = lookup.id
WHERE timestamp_millis >= (EXTRACT(EPOCH FROM timestamp with time zone '2024-04-18 00:00:00 -04') * 1000)
	AND timestamp_millis < (EXTRACT(EPOCH FROM timestamp with time zone '2024-04-19 00:00:00 -04') * 1000)
ORDER BY timestamp_millis ASC;
