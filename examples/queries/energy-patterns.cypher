// Neo4j Cypher Queries for Energy Pattern Analysis

// 1. Find energy consumption patterns by device type
MATCH (device:Entity)-[:HAD_STATE]->(state:State)
WHERE device.type CONTAINS 'energy' 
  AND state.timestamp > datetime() - duration('P7D')
RETURN device.entity_id, 
       device.type,
       avg(toFloat(state.value)) as avg_consumption,
       max(toFloat(state.value)) as peak_consumption,
       count(state) as reading_count
ORDER BY avg_consumption DESC
LIMIT 20;

// 2. Find devices that correlate with high energy usage
MATCH (energy:Entity {type: 'energy_sensor'})-[:HAD_STATE]->(energy_state:State)
MATCH (device:Entity)-[:HAD_STATE]->(device_state:State)
WHERE abs(duration.between(
  datetime(energy_state.timestamp), 
  datetime(device_state.timestamp)
).seconds) < 300
  AND toFloat(energy_state.value) > 1000
RETURN device.entity_id,
       device.type,
       count(*) as correlation_count,
       avg(toFloat(energy_state.value)) as avg_energy_during_activation
ORDER BY correlation_count DESC
LIMIT 15;

// 3. Find hourly energy usage patterns
MATCH (energy:Entity)-[:HAD_STATE]->(state:State)
WHERE energy.type CONTAINS 'energy'
  AND state.timestamp > datetime() - duration('P30D')
WITH datetime(state.timestamp).hour as hour,
     toFloat(state.value) as consumption
RETURN hour,
       avg(consumption) as avg_consumption,
       max(consumption) as peak_consumption,
       count(*) as reading_count
ORDER BY hour;

// 4. Find energy waste opportunities (devices left on)
MATCH (device:Entity)-[:HAD_STATE]->(state1:State)
MATCH (device)-[:HAD_STATE]->(state2:State)
WHERE device.type IN ['light_device', 'switch_device']
  AND state1.value = 'on'
  AND state2.value = 'on'
  AND state1.timestamp < state2.timestamp
  AND duration.between(
    datetime(state1.timestamp), 
    datetime(state2.timestamp)
  ).hours > 4
RETURN device.entity_id,
       device.type,
       count(*) as long_on_periods,
       avg(duration.between(
         datetime(state1.timestamp), 
         datetime(state2.timestamp)
       ).hours) as avg_hours_on
ORDER BY long_on_periods DESC
LIMIT 10;

// 5. Find rooms with highest energy impact
MATCH (device:Entity)-[:SAME_ROOM]->(room:Location)
MATCH (device)-[:AFFECTS_ENERGY]->(energy:Entity)
MATCH (energy)-[:HAD_STATE]->(state:State)
WHERE state.timestamp > datetime() - duration('P7D')
RETURN room.name,
       count(DISTINCT device) as device_count,
       avg(toFloat(state.value)) as avg_energy_impact,
       sum(toFloat(state.value)) as total_energy
ORDER BY total_energy DESC;
