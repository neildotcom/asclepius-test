import * as React from 'react';
import { getTranscript, Transcript } from '../services/transcriptService';
import Container from '@cloudscape-design/components/container';
import Header from '@cloudscape-design/components/header';
import ColumnLayout from "@cloudscape-design/components/column-layout";
import Box from "@cloudscape-design/components/box";
import { getVisitById, Visit } from '../services/visitService';
import { SpaceBetween, KeyValuePairs } from '@cloudscape-design/components';
import Button from "@cloudscape-design/components/button";


interface PatientStep2Props {
    sessionId: string | null;
}


interface ConversationEntry {
    message: string;
    speaker: 'CLINICIAN' | 'PATIENT';
    timestamp: number;
}

const HCTranscript: React.FC<PatientStep2Props> = ({ sessionId }) => {
    const [transcript, setTranscript] = React.useState<Transcript | null>(null);
    const [visit, setVisit] = React.useState<Visit | null>(null);
    const [isLoadingTranscript, setIsLoadingTranscript] = React.useState(true);
    const [isLoadingVisit, setIsLoadingVisit] = React.useState(true);
    const [error, setError] = React.useState<string | null>(null);
    const [retryCount, setRetryCount] = React.useState(0);
    const [isRetrying, setIsRetrying] = React.useState(false);
    const maxRetries = 20; // Will retry up to 10 times
    const retryInterval = 3000; // 3 seconds between retries

    const fetchVisitData = async () => {
        if (!sessionId) {
            setError("No session ID provided");
            setIsLoadingVisit(false);
            return;
        }

        try {
            setIsLoadingVisit(true);
            setError(null);
            const visitData = await getVisitById(sessionId);
            console.log('Visit Data:', visitData);

            if (!visitData || !visitData.soapNote) {
                // If data is not ready, throw error to trigger retry
                throw new Error("Visit data not fully processed yet");
            }

            setVisit(visitData);
            setIsRetrying(false); // Reset retry state on success
            setRetryCount(0); // Reset retry count on success
            setIsLoadingVisit(false); // Set loading to false on success
        } catch (error) {
            console.error("Error fetching visit:", error);
            
            if (retryCount < maxRetries) {
                setIsRetrying(true);
                setRetryCount(prev => prev + 1);
                // Schedule next retry
                setTimeout(() => {
                    fetchVisitData();
                }, retryInterval);
            } else {
                setError("Failed to fetch visit data after multiple attempts");
                setIsRetrying(false);
                setIsLoadingVisit(false); // Set loading to false on max retries
            }
        } finally {
            if (retryCount >= maxRetries) {
                setIsLoadingVisit(false);
            }
        }
    };

    const fetchTranscriptData = async () => {
        if (!sessionId) {
            setError("No session ID provided");
            setIsLoadingTranscript(false);
            return;
        }

        try {
            setIsLoadingTranscript(true);
            setError(null);
            // Modify getTranscript to accept sessionId
            const transcriptData = await getTranscript(sessionId);
            console.log('Transcript Data:', transcriptData);
            setTranscript(transcriptData);
        } catch (error) {
            console.error("Error fetching transcript:", error);
            setError("Failed to fetch transcript");
        } finally {
            setIsLoadingTranscript(false);
        }
    };



    // Add a manual retry function
    const handleManualRetry = () => {
        setRetryCount(0);
        setError(null);
        setIsRetrying(false);
        fetchVisitData();
    };

    React.useEffect(() => {
        if (sessionId) {
            fetchVisitData();
            fetchTranscriptData();
        }
    }, [sessionId]);

    // Loading UI Component
    const LoadingUI = () => (
        <SpaceBetween size="m">
            <Box textAlign="center">
                <div>Loading visit data... {retryCount > 0 && `(Attempt ${retryCount}/${maxRetries})`}</div>
                {isRetrying && (
                    <div>
                        Waiting for data to be processed...
                        <br />
                        This may take up to 30 seconds
                    </div>
                )}
            </Box>
        </SpaceBetween>
    );

    // Error UI Component with Retry Button
    const ErrorUI = () => (
        <SpaceBetween size="m">
            <Box textAlign="center">
                <div>{error}</div>
                <Button onClick={handleManualRetry}>
                    Retry Loading
                </Button>
            </Box>
        </SpaceBetween>
    );

    const renderConversation = (conversation: any) => {
        try {
            console.log('Conversation data:', conversation);
            
            // Ensure conversation is an array
            const conversationArray = Array.isArray(conversation) ? conversation : [];
            
            const parsedConversation: ConversationEntry[] = conversationArray.map((entry: any) => {
                console.log('Processing entry:', entry);
                if (!entry.message || !entry.speaker || !entry.timestamp) {
                    console.error('Invalid entry structure:', entry);
                    return null;
                }
                
                return {
                    message: entry.message,
                    speaker: entry.speaker,
                    timestamp: Number(entry.timestamp)
                };
            }).filter((entry): entry is ConversationEntry => entry !== null);

            if (parsedConversation.length === 0) {
                return <div>No valid conversation entries found</div>;
            }

            return (
                <div>
                    {parsedConversation.map((entry, index) => (
                        <Box
                            key={index}
                            margin={{ bottom: "s" }}
                            padding="s"
                            color={entry.speaker === "CLINICIAN" ? "text-body-secondary" : "text-body"}
                        >
                            <strong>{entry.speaker}:</strong> {entry.message}
                            
                        </Box>
                    ))}
                </div>
            );
        } catch (e) {
            console.error("Error parsing conversation:", e);
            return <div>Error parsing conversation data</div>;
        }
    };


    return (
        <ColumnLayout columns={2}>
            <div>
                <Container
                    header={
                        <Header variant="h2">
                            Transcript
                        </Header>
                    }
                >
                    {isLoadingVisit ? (
                        <LoadingUI />
                    ) : error ? (
                        <ErrorUI />
                    ) : !visit ? (
                        <div>No visit data available</div>
                    ) : !visit.conversation ? (
                        <div>No transcript found for this visit</div>
                    ) : (
                        renderConversation(visit.conversation)
                    )}
                </Container>
            </div>
            <div>
                <Container
                    header={
                        <Header variant="h2">
                            Insights
                        </Header>
                    }
                >

                    {isLoadingVisit ? (
                        <div>Loading insights...</div>
                    ) : error ? (
                        <div>{error}</div>
                    ) : visit ? (
                        <SpaceBetween size="m">
                            <Container
                                header={<Header variant="h3">Subjective</Header>}
                            >
                                <KeyValuePairs
                                    columns={1}
                                    items={[
                                        { label: "Chief Complaint", value: visit.soapNote.subjective.chiefComplaint },
                                        { label: "History of Present Illness", value: visit.soapNote.subjective.historyOfPresentIllness }
                                    ]}
                                />
                            </Container>

                            <Container
                                header={<Header variant="h3">Objective</Header>}
                            >
                                <KeyValuePairs
                                    columns={1}
                                    items={[
                                        { label: "Objective", value: visit.soapNote.objective }
                                    ]}
                                />
                            </Container>

                            <Container
                                header={<Header variant="h3">Assessment</Header>}
                            >
                                <KeyValuePairs
                                    columns={1}
                                    items={[
                                        { label: "Primary Diagnosis", value: visit.soapNote.assessment.primaryDiagnosis.condition },
                                        { label: "Primary Diagnosis ICD10 Code", value: visit.soapNote.assessment.primaryDiagnosis.icd10 },
                                        { label: "Secondary Diagnosis", value: visit.soapNote.assessment.secondaryDiagnosis.condition },
                                        { label: "Secondary Diagnosis ICD10 Code", value: visit.soapNote.assessment.secondaryDiagnosis.icd10 }
                                    ]}
                                />
                            </Container>

                            <Container
                                header={<Header variant="h3">Plan</Header>}
                            >
                                <KeyValuePairs
                                    columns={1}
                                    items={[
                                        { label: "Treatment", value: visit.soapNote.plan.treatment },
                                        { label: "Followup", value: visit.soapNote.plan.followUp }
                                    ]}
                                />
                            </Container>
                        </SpaceBetween>
                    ) : (
                        <div>No SOAP note found</div>
                    )}
                </Container>
            </div>
        </ColumnLayout>
    );
};


export default HCTranscript;
