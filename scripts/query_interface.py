import asyncio
from graphiti import Graphiti
import json
import os
from dotenv import load_dotenv

load_dotenv()

class GraphitiQuery:
    def __init__(self):
        self.graphiti = Graphiti()
    
    async def get_energy_insights(self, timeframe="last 24 hours"):
        """Get energy usage insights"""
        query = f"energy usage patterns and correlations in the {timeframe}"
        results = await self.graphiti.search(query, limit=20)
        return results
    
    async def get_device_relationships(self, device_name):
        """Find relationships for a specific device"""
        query = f"all relationships and interactions involving {device_name}"
        results = await self.graphiti.search(query, limit=15)
        return results
    
    async def get_automation_suggestions(self):
        """Get automation suggestions based on patterns"""
        query = "repeated patterns and sequences that could be automated"
        results = await self.graphiti.search(query, limit=10)
        return results
    
    async def get_anomalies(self):
        """Detect unusual patterns"""
        query = "unusual or anomalous device behavior patterns"
        results = await self.graphiti.search(query, limit=10)
        return results
    
    async def get_room_analysis(self, room_name):
        """Analyze patterns for a specific room"""
        query = f"device usage patterns and relationships in {room_name}"
        results = await self.graphiti.search(query, limit=15)
        return results

# Example usage
async def main():
    query = GraphitiQuery()
    
    print("? Energy Insights:")
    energy = await query.get_energy_insights()
    for insight in energy:
        print(f"  - {insight}")
    
    print("\n? Automation Suggestions:")
    automation = await query.get_automation_suggestions()
    for suggestion in automation:
        print(f"  - {suggestion}")
    
    print("\n?? Anomalies Detected:")
    anomalies = await query.get_anomalies()
    for anomaly in anomalies:
        print(f"  - {anomaly}")

if __name__ == "__main__":
    asyncio.run(main())
