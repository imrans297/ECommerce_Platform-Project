import React, { useEffect, useState } from 'react';
import { checkServiceHealth } from '../services/api';

const Home = () => {
  const [services, setServices] = useState({
    'user-service': 'checking...',
    'product-service': 'checking...',
    'order-service': 'checking...',
    'notification-service': 'checking...'
  });

  useEffect(() => {
    const checkAllServices = async () => {
      const serviceNames = Object.keys(services);
      const results = {};
      
      for (const service of serviceNames) {
        try {
          const health = await checkServiceHealth(service);
          results[service] = health.status === 'healthy' ? 'healthy' : 'error';
        } catch (error) {
          results[service] = 'error';
        }
      }
      
      setServices(results);
    };

    checkAllServices();
  }, []);

  return (
    <div>
      <h2>System Status</h2>
      <div className="service-status">
        {Object.entries(services).map(([service, status]) => (
          <div key={service} className={`status-card status-${status}`}>
            <h3>{service}</h3>
            <p>{status}</p>
          </div>
        ))}
      </div>
    </div>
  );
};

export default Home;