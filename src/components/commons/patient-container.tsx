import * as React from "react";
import { useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { useState } from "react";
import Container from "@cloudscape-design/components/container";
import KeyValuePairs from "@cloudscape-design/components/key-value-pairs";
import Header from "@cloudscape-design/components/header";
import SpaceBetween from "@cloudscape-design/components/space-between";
import Button from "@cloudscape-design/components/button";
import { ConsentModal } from "./modal";
import Modal from "@cloudscape-design/components/modal";
import Box from "@cloudscape-design/components/box";
import { getPatientById, Patient } from "../../services/patientService";
import { ContentLayout } from "@cloudscape-design/components";
import { VisitListContent } from "./visit-list";


export function patientContainer() {
  const [visible, setVisible] = useState(false);
  const [patient, setPatient] = useState<Patient | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const { patientID } = useParams<{ patientID: string }>();

  const navigate = useNavigate();


  useEffect(() => {
    const fetchPatientData = async () => {
      if (!patientID) {
        setError('No patient ID provided');
        setLoading(false);
        return;
      }

      try {
        const patientData = await getPatientById(patientID);
        if (patientData) {
          setPatient(patientData);
        } else {
          setError('Patient not found');
        }
      } catch (err) {
        console.error('Error fetching patient details:', err);
        setError('Failed to load patient details');
      } finally {
        setLoading(false);
      }
    };

    fetchPatientData();
  }, [patientID]);

  return (
<ContentLayout
      header={
        <SpaceBetween size="m">
          <Header
            variant="h1"
            description="Patient information and medical records"
          >
            {patient ? `${patient.firstName} ${patient.lastName}` : 'Patient Details'}
          </Header>
        </SpaceBetween>
      }
    >
      {loading ? (
        <Container>
          <Box padding="l">Loading patient details...</Box>
        </Container>
      ) : error ? (
        <Container>
          <Box padding="l">{error}</Box>
        </Container>
      ) : !patient ? (
        <Container>
          <Box padding="l">No patient found</Box>
        </Container>
      ) : (
        <SpaceBetween size="l">
          <Container variant="stacked"
          >
            <SpaceBetween size="m">
              <Box>
                <SpaceBetween size="s">
                <KeyValuePairs
                  columns={3}
                  items={[
                    { label: "Patient id", value: patient.patientID },
                    { label: "DOB", value: patient.dob }
                  ]}
                />
                  
                </SpaceBetween>
              </Box>
            </SpaceBetween>
          </Container>

          <Container
            header={
              <Header
                variant="h2"
                description="Click to start recording and generating insights."
                actions={
                  <SpaceBetween
                    direction="horizontal"
                    size="xs"
                  >
                    <Button variant="primary" onClick={() => setVisible(true)}>Begin</Button>

                    <Modal
                      onDismiss={() => setVisible(false)}
                      visible={visible}
                      footer={
                        <Box float="right">
                          <SpaceBetween direction="horizontal" size="xs">
                            <Button variant="link" onClick={() => setVisible(false)}>
                              Cancel
                            </Button>
                            <Button variant="primary"
                              onClick={() => {
                                setVisible(true);
                                navigate(`/patients/${patientID}/new-visit`);}}>Confirmed</Button>
                          </SpaceBetween>
                        </Box>
                      }
                      header={<React.Fragment>Recording Consent</React.Fragment>}
                    >
                      Advise the patient that the consultation will be recorded and obtain their
                      consent.
                    </Modal>

                  </SpaceBetween>
                }
              >
                Start New Visit
              </Header>
            }
          >
          </Container>

        {/* Additional patient information containers can be added here */}
        <Container
            header={
              <Header variant="h2">Medical History</Header>
            }
          >
            <Box padding="l">
              {/* Add medical history content here */}
              Medical history information will be displayed here
            </Box>
          </Container>

       

          {/* Add previous visits history as a table, with each record clickable and leads into detailed visit view */}
          <VisitListContent patientId={patient.patientID} />
      

        </SpaceBetween>

        
      )}
    </ContentLayout>

  );
}
