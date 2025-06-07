import asyncio
import aiohttp
import json
import logging
from typing import List, Dict, Any

class OllamaClient:
    def __init__(self, base_url: str = "http://ollama:11434", model: str = "llama3.2:3b"):
        self.base_url = base_url
        self.model = model
        self.embed_model = "nomic-embed-text"
        
    async def generate_completion(self, prompt: str, system_prompt: str = None) -> str:
        """Generate completion using Ollama"""
        try:
            async with aiohttp.ClientSession() as session:
                payload = {
                    "model": self.model,
                    "prompt": prompt,
                    "system": system_prompt,
                    "stream": False,
                    "options": {
                        "temperature": 0.1,  # Lower temperature for consistent extractions
                        "top_p": 0.9
                    }
                }
                
                async with session.post(
                    f"{self.base_url}/api/generate",
                    json=payload
                ) as response:
                    if response.status == 200:
                        result = await response.json()
                        return result.get("response", "")
                    else:
                        logging.error(f"Ollama API error: {response.status}")
                        return ""
                        
        except Exception as e:
            logging.error(f"Error calling Ollama: {e}")
            return ""
    
    async def generate_embeddings(self, text: str) -> List[float]:
        """Generate embeddings using Ollama"""
        try:
            async with aiohttp.ClientSession() as session:
                payload = {
                    "model": self.embed_model,
                    "prompt": text
                }
                
                async with session.post(
                    f"{self.base_url}/api/embeddings",
                    json=payload
                ) as response:
                    if response.status == 200:
                        result = await response.json()
                        return result.get("embedding", [])
                    else:
                        logging.error(f"Ollama embedding error: {response.status}")
                        return []
                        
        except Exception as e:
            logging.error(f"Error generating embeddings: {e}")
            return []
    
    async def extract_entities_and_relationships(self, event_text: str) -> Dict[str, Any]:
        """Extract entities and relationships from HA event using Ollama"""
        
        system_prompt = """You are an expert at analyzing smart home device events. 
        Extract entities and their relationships from the given text.
        Return ONLY valid JSON with this exact structure:
        {
            "entities": [
                {"name": "entity_name", "type": "entity_type", "properties": {"key": "value"}}
            ],
            "relationships": [
                {"source": "entity1", "target": "entity2", "type": "relationship_type", "properties": {"key": "value"}}
            ]
        }"""
        
        prompt = f"""Analyze this smart home event and extract entities and relationships:

        Event: {event_text}
        
        Extract:
        - Devices (sensors, lights, switches, etc.)
        - Locations (rooms, areas)
        - Values (temperatures, states, measurements)
        - Time information
        - Relationships between entities
        
        Return only the JSON structure."""
        
        response = await self.generate_completion(prompt, system_prompt)
        
        try:
            # Clean up response and parse JSON
            response = response.strip()
            if response.startswith("```json"):
                response = response[7:-3]
            elif response.startswith("```"):
                response = response[3:-3]
            
            return json.loads(response)
        except json.JSONDecodeError as e:
            logging.error(f"Failed to parse Ollama response as JSON: {e}")
            logging.error(f"Response was: {response}")
            return {"entities": [], "relationships": []}
    
    async def analyze_patterns(self, events_summary: str) -> List[str]:
        """Analyze patterns and provide insights"""
        
        system_prompt = """You are a smart home analytics expert. 
        Analyze device usage patterns and provide actionable insights.
        Focus on energy efficiency, automation opportunities, and unusual patterns."""
        
        prompt = f"""Analyze these smart home patterns and provide insights:

        {events_summary}
        
        Provide specific, actionable insights about:
        1. Energy usage patterns and optimization opportunities
        2. Automation suggestions based on repeated patterns
        3. Unusual or concerning device behaviors
        4. Seasonal or time-based patterns
        
        Be specific and practical."""
        
        response = await self.generate_completion(prompt, system_prompt)
        
        # Split response into individual insights
        insights = [insight.strip() for insight in response.split('\n') if insight.strip() and not insight.strip().startswith('#')]
        return insights[:10]  # Limit to top 10 insights
