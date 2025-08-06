import React, { useState } from 'react';
import Container from '@cloudscape-design/components/container';
import Header from '@cloudscape-design/components/header';
import SpaceBetween from '@cloudscape-design/components/space-between';
import StartTranscriptionButton from '../components/StartTranscriptionButton';
import LiveTranscription from '../components/LiveTranscription';


interface PatientStep1Props {
  onSessionStart: (sessionId: string) => void;
}

export const PatientStep1: React.FC<PatientStep1Props> = ({ onSessionStart }) => {
  const [currentTranscription, setCurrentTranscription] = useState('');
  const [isPartial, setIsPartial] = useState(false);
  const [currentSessionId, setCurrentSessionId] = useState<string | null>(null);
  const [isSessionInProgress, setIsSessionInProgress] = useState(false);
  const [isSessionEnded, setIsSessionEnded] = useState(false); // Add this state

  const handleTranscriptionUpdate = (transcription: string, partial: boolean) => {
    setCurrentTranscription(transcription);
    setIsPartial(partial);
  };

  const handleSessionStart = (sessionId: string | null) => {
    if (sessionId) {
      setCurrentSessionId(sessionId);
      setIsSessionInProgress(true);
      setIsSessionEnded(false); // Reset session ended state
      onSessionStart(sessionId);
    } else {
      // Session ended
      setIsSessionInProgress(false);
      setIsSessionEnded(true); // Set session ended to true
    }
  };

  const getHeaderText = () => {
    if (isSessionInProgress) {
      return <span style={{ color: '#16A34A' }}>Session in Progress</span>;
    } else if (isSessionEnded) {
      return <span style={{ color: '#2563EB' }}>Session Recorded</span>;
    } else {
      return "Press button to start the session";
    }
  };

  return (
    <Container 
      header={
        <Header
          variant="h2"
          actions={
            <SpaceBetween
              direction="horizontal"
              size="xs"
            >
              <StartTranscriptionButton 
                onTranscriptionUpdate={handleTranscriptionUpdate} 
                onSessionStart={handleSessionStart}
              />
            </SpaceBetween>
          }
        >
          {getHeaderText()}
        </Header> 
      }
    >
      {currentSessionId && <div>Patient Session ID: {currentSessionId}</div>}
      <LiveTranscription
        transcription={currentTranscription}
        isPartial={isPartial}
      />
    </Container>
  );
};

export default PatientStep1;
