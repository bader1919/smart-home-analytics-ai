// Neo4j Cypher Queries for Automation Suggestions

// 1. Find motion sensor to light activation patterns
MATCH (motion:Entity {type: 'motion_sensor'})-[:HAD_STATE]->(motion_state:State {value: 'on'})
MATCH (light:Entity {type: 'light_device'})-[:HAD_STATE]->(light_state:State {value: 'on'})
MATCH (motion)-[:SAME_ROOM]->(light)
WHERE abs(duration.between(
  datetime(motion_state.timestamp), 
  datetime(light_state.timestamp)
).seconds) < 300
RETURN motion.entity_id,
       light.entity_id,
       count(*) as activation_correlation,
       avg(duration.between(
         datetime(motion_state.timestamp), 
         datetime(light_state.timestamp)
       ).seconds) as avg_delay_seconds
HAVING activation_correlation > 5
ORDER BY activation_correlation DESC;

// 2. Find repeated daily patterns
MATCH (device:Entity)-[:HAD_STATE]->(state:State)
WHERE state.timestamp > datetime() - duration('P30D')
WITH device,
     datetime(state.timestamp).hour as hour,
     datetime(state.timestamp).dayOfWeek as day_of_week,
     state.value as state_value
WITH device, hour, day_of_week, state_value,
     count(*) as pattern_frequency
WHERE pattern_frequency > 10
RETURN device.entity_id,
       hour,
       CASE day_of_week
         WHEN 1 THEN 'Monday'
         WHEN 2 THEN 'Tuesday'
         WHEN 3 THEN 'Wednesday'
         WHEN 4 THEN 'Thursday'
         WHEN 5 THEN 'Friday'
         WHEN 6 THEN 'Saturday'
         WHEN 7 THEN 'Sunday'
       END as day,
       state_value,
       pattern_frequency
ORDER BY pattern_frequency DESC
LIMIT 20;

// 3. Find devices that are always activated together
MATCH (device1:Entity)-[:HAD_STATE]->(state1:State)
MATCH (device2:Entity)-[:HAD_STATE]->(state2:State)
WHERE device1.entity_id < device2.entity_id
  AND state1.value = 'on'
  AND state2.value = 'on'
  AND abs(duration.between(
    datetime(state1.timestamp), 
    datetime(state2.timestamp)
  ).minutes) < 5
RETURN device1.entity_id,
       device2.entity_id,
       count(*) as simultaneous_activations
HAVING simultaneous_activations > 10
ORDER BY simultaneous_activations DESC
LIMIT 15;

// 4. Find temperature-based automation opportunities
MATCH (temp:Entity {type: 'temperature_sensor'})-[:HAD_STATE]->(temp_state:State)
MATCH (climate:Entity {type: 'climate_device'})-[:HAD_STATE]->(climate_state:State)
WHERE abs(duration.between(
  datetime(temp_state.timestamp), 
  datetime(climate_state.timestamp)
).minutes) < 30
  AND toFloat(temp_state.value) < 18  -- Cold temperature threshold
  AND climate_state.value = 'heat'
RETURN temp.entity_id,
       climate.entity_id,
       count(*) as heating_correlations,
       avg(toFloat(temp_state.value)) as avg_trigger_temp
ORDER BY heating_correlations DESC;

// 5. Find presence-based automation opportunities
MATCH (presence:Entity {type: 'presence_sensor'})-[:HAD_STATE]->(presence_state:State)
MATCH (device:Entity)-[:HAD_STATE]->(device_state:State)
WHERE presence_state.value = 'away'
  AND device_state.value = 'on'
  AND abs(duration.between(
    datetime(presence_state.timestamp), 
    datetime(device_state.timestamp)
  ).minutes) < 60
RETURN device.entity_id,
       device.type,
       count(*) as left_on_when_away,
       'Turn off when nobody home' as automation_suggestion
ORDER BY left_on_when_away DESC
LIMIT 10;
