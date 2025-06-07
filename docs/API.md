# API Documentation

## Graphiti Query Interface

The Smart Home Analytics platform provides several APIs for querying insights and managing the knowledge graph.

### Python API

#### Basic Usage

```python
from scripts.query_interface import GraphitiQuery
import asyncio

async def main():
    query = GraphitiQuery()
    
    # Get energy insights
    energy_insights = await query.get_energy_insights("last 24 hours")
    print("Energy Insights:", energy_insights)
    
    # Get automation suggestions
    automations = await query.get_automation_suggestions()
    print("Automation Suggestions:", automations)

asyncio.run(main())
```

#### Available Methods

##### Energy Analysis

```python
# Get energy usage patterns
insights = await query.get_energy_insights(timeframe="last 7 days")

# Parameters:
# - timeframe: "last 24 hours", "last 7 days", "last 30 days", "last year"
# Returns: List of energy-related insights and patterns
```

##### Device Relationships

```python
# Find relationships for specific devices
relationships = await query.get_device_relationships("living_room_lights")

# Parameters:
# - device_name: Entity ID or friendly name
# Returns: List of related devices and their interaction patterns
```

##### Automation Suggestions

```python
# Get automation opportunities
suggestions = await query.get_automation_suggestions()

# Returns: List of suggested automations based on usage patterns
```

##### Anomaly Detection

```python
# Detect unusual patterns
anomalies = await query.get_anomalies()

# Returns: List of detected anomalous behaviors
```

##### Room Analysis

```python
# Analyze specific room patterns
room_data = await query.get_room_analysis("kitchen")

# Parameters:
# - room_name: Name of the room to analyze
# Returns: Room-specific usage patterns and insights
```

### Ollama Client API

#### Direct Ollama Integration

```python
from scripts.ollama_client import OllamaClient
import asyncio

async def main():
    ollama = OllamaClient(
        base_url="http://localhost:11434",
        model="llama3.2:3b"
    )
    
    # Generate text completion
    response = await ollama.generate_completion(
        prompt="Analyze this smart home pattern: lights turn on at 6 PM daily",
        system_prompt="You are a smart home expert"
    )
    print("Analysis:", response)
    
    # Generate embeddings
    embeddings = await ollama.generate_embeddings("living room temperature sensor")
    print("Embeddings dimension:", len(embeddings))
    
    # Extract entities from event
    entities = await ollama.extract_entities_and_relationships(
        "Kitchen light turned on at 6:30 PM when motion detected"
    )
    print("Extracted entities:", entities)

asyncio.run(main())
```

### Neo4j Cypher Queries

#### Direct Database Access

```python
from neo4j import GraphDatabase

class Neo4jClient:
    def __init__(self):
        self.driver = GraphDatabase.driver(
            "bolt://localhost:7687",
            auth=("neo4j", "smarthome123")
        )
    
    def get_energy_devices(self):
        with self.driver.session() as session:
            result = session.run("""
                MATCH (device:Entity)-[:HAD_STATE]->(state:State)
                WHERE device.type CONTAINS 'energy'
                RETURN device.entity_id, 
                       avg(toFloat(state.value)) as avg_consumption
                ORDER BY avg_consumption DESC
                LIMIT 10
            """)
            return [record.data() for record in result]
```

#### Common Query Patterns

##### Find Device Correlations

```cypher
// Find devices that activate together
MATCH (d1:Entity)-[:HAD_STATE]->(s1:State {value: 'on'})
MATCH (d2:Entity)-[:HAD_STATE]->(s2:State {value: 'on'})
WHERE d1.entity_id < d2.entity_id
  AND abs(duration.between(
    datetime(s1.timestamp), 
    datetime(s2.timestamp)
  ).minutes) < 5
RETURN d1.entity_id, d2.entity_id, count(*) as correlations
ORDER BY correlations DESC
LIMIT 10
```

##### Energy Usage Patterns

```cypher
// Hourly energy consumption patterns
MATCH (energy:Entity)-[:HAD_STATE]->(state:State)
WHERE energy.type CONTAINS 'energy'
  AND state.timestamp > datetime() - duration('P7D')
WITH datetime(state.timestamp).hour as hour,
     toFloat(state.value) as consumption
RETURN hour,
       avg(consumption) as avg_consumption,
       max(consumption) as peak_consumption
ORDER BY hour
```

##### Motion and Light Correlation

```cypher
// Find motion-triggered lighting patterns
MATCH (motion:Entity {type: 'motion_sensor'})-[:HAD_STATE]->(ms:State {value: 'on'})
MATCH (light:Entity {type: 'light_device'})-[:HAD_STATE]->(ls:State {value: 'on'})
WHERE abs(duration.between(
  datetime(ms.timestamp), 
  datetime(ls.timestamp)
).seconds) < 300
RETURN motion.entity_id,
       light.entity_id,
       count(*) as activations,
       avg(duration.between(
         datetime(ms.timestamp), 
         datetime(ls.timestamp)
       ).seconds) as avg_delay
ORDER BY activations DESC
```

### REST API (Optional)

#### Creating a FastAPI Wrapper

```python
# api_server.py
from fastapi import FastAPI, HTTPException
from scripts.query_interface import GraphitiQuery
import asyncio

app = FastAPI(title="Smart Home Analytics API")
query_client = GraphitiQuery()

@app.get("/energy/insights")
async def get_energy_insights(timeframe: str = "last 24 hours"):
    """Get energy usage insights"""
    try:
        insights = await query_client.get_energy_insights(timeframe)
        return {"insights": insights, "timeframe": timeframe}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/devices/{device_name}/relationships")
async def get_device_relationships(device_name: str):
    """Get relationships for a specific device"""
    try:
        relationships = await query_client.get_device_relationships(device_name)
        return {"device": device_name, "relationships": relationships}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/automation/suggestions")
async def get_automation_suggestions():
    """Get automation suggestions"""
    try:
        suggestions = await query_client.get_automation_suggestions()
        return {"suggestions": suggestions}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/anomalies")
async def get_anomalies():
    """Get detected anomalies"""
    try:
        anomalies = await query_client.get_anomalies()
        return {"anomalies": anomalies}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/rooms/{room_name}/analysis")
async def get_room_analysis(room_name: str):
    """Get room-specific analysis"""
    try:
        analysis = await query_client.get_room_analysis(room_name)
        return {"room": room_name, "analysis": analysis}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

#### Running the API Server

```bash
# Install FastAPI
pip install fastapi uvicorn

# Run the server
python api_server.py

# Access API documentation
# http://localhost:8000/docs
```

#### API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/energy/insights` | GET | Get energy usage insights |
| `/devices/{device_name}/relationships` | GET | Get device relationships |
| `/automation/suggestions` | GET | Get automation suggestions |
| `/anomalies` | GET | Get detected anomalies |
| `/rooms/{room_name}/analysis` | GET | Get room analysis |

### WebSocket API (Real-time)

#### Real-time Event Streaming

```python
# websocket_server.py
from fastapi import FastAPI, WebSocket
import asyncio
import json

app = FastAPI()

@app.websocket("/ws/events")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    
    # Subscribe to live events
    while True:
        try:
            # Get latest insights every 10 seconds
            insights = await query_client.get_energy_insights("last 1 hour")
            
            await websocket.send_text(json.dumps({
                "type": "energy_update",
                "data": insights
            }))
            
            await asyncio.sleep(10)
            
        except Exception as e:
            print(f"WebSocket error: {e}")
            break
```

### Data Export API

#### Export Functions

```python
# export_api.py
import pandas as pd
from datetime import datetime, timedelta

class DataExporter:
    def __init__(self, neo4j_driver):
        self.driver = neo4j_driver
    
    def export_energy_data(self, days=30):
        """Export energy data to CSV"""
        with self.driver.session() as session:
            result = session.run("""
                MATCH (energy:Entity)-[:HAD_STATE]->(state:State)
                WHERE energy.type CONTAINS 'energy'
                  AND state.timestamp > datetime() - duration({days: $days})
                RETURN energy.entity_id as device,
                       state.timestamp as timestamp,
                       toFloat(state.value) as consumption
                ORDER BY state.timestamp
            """, days=f"P{days}D")
            
            data = [record.data() for record in result]
            df = pd.DataFrame(data)
            
            filename = f"energy_export_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"
            df.to_csv(filename, index=False)
            return filename
    
    def export_automation_report(self):
        """Export automation suggestions to JSON"""
        # Implementation here
        pass
```

### Error Handling

#### Common Error Responses

```python
# Error handling patterns
try:
    result = await query_client.get_energy_insights()
except ConnectionError:
    print("Database connection failed")
except TimeoutError:
    print("Query timed out")
except Exception as e:
    print(f"Unexpected error: {e}")
```

### Rate Limiting

#### API Rate Limits

```python
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

@app.get("/energy/insights")
@limiter.limit("10/minute")
async def get_energy_insights(request: Request, timeframe: str = "last 24 hours"):
    # Implementation
    pass
```

For more examples and advanced usage, see the [examples/](../examples/) directory.
