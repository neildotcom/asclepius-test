import * as React from "react";
import { useEffect } from "react";
import { useParams } from "react-router-dom";
import { useState } from "react";
import Container from "@cloudscape-design/components/container";
import KeyValuePairs from "@cloudscape-design/components/key-value-pairs";
import Header from "@cloudscape-design/components/header";
import Table from "@cloudscape-design/components/table";
import SpaceBetween from "@cloudscape-design/components/space-between";
import Button from "@cloudscape-design/components/button";
import { ConsentModal } from "./modal";
import Modal from "@cloudscape-design/components/modal";
import Box from "@cloudscape-design/components/box";
import { getPatientById, Patient } from "../../services/patientService";
import { getVisitById, Visit } from "../../services/visitService";
import { ContentLayout } from "@cloudscape-design/components";
import { BreadcrumbGroup } from "@cloudscape-design/components";


export function VisitContainer() {
  const [visible, setVisible] = useState(false);
  const [visit, setVisit] = useState<Visit | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const { visitID } = useParams<{ visitID: string }>();
  console.log("URL Parameter visitID:", visitID)


  useEffect(() => {
    const fetchVisitData = async () => {
      if (!visitID) {
        setError('No visit ID provided');
        setLoading(false);
        return;
      }

      try {
        const visitData = await getVisitById(visitID);
        if (visitData) {
          setVisit(visitData);
        } else {
          setError('Visit not found');
        }
      } catch (err) {
        console.error('Error fetching visit details:', err);
        setError('Failed to load visit details');
      } finally {
        setLoading(false);
      }
    };

    fetchVisitData();
  }, [visitID]);

  // const breadcrumbItems = [
  //   { text: 'Patients', href: '/' },
  //   { text: patient ? `${patient.firstName} ${patient.lastName}` : 'Patient Details', href: '#' },
  // ];

  return (
<ContentLayout
      header={
        <SpaceBetween size="m">
          <Header
            variant="h1"
            description="Visit Records"
          >
            {visit ? ` ${visit.date}` : 'Visit Details'}
          </Header>
        </SpaceBetween>
      }
    >
      {loading ? (
        <Container>
          <Box padding="l">Loading visit details...</Box>
        </Container>
      ) : error ? (
        <Container>
          <Box padding="l">{error}</Box>
        </Container>
      ) : !visit ? (
        <Container>
          <Box padding="l">No visit found</Box>
        </Container>
      ) : (
        <SpaceBetween size="l">
          <Container variant="stacked">
            <SpaceBetween size="m">
              <KeyValuePairs
                columns={2}
                items={[
                  { label: "Patient ID", value: visit.patientID }
                ]}
              />
            </SpaceBetween>
          </Container>

          <Container
            header={<Header variant="h2">SOAP Note</Header>}
          >
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
          </Container>
        </SpaceBetween>
      )}
    </ContentLayout>

  );
}
