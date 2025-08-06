import * as React from "react";
import { useState } from "react";
import Form from "@cloudscape-design/components/form";
import SpaceBetween from "@cloudscape-design/components/space-between";
import Button from "@cloudscape-design/components/button";
import Container from "@cloudscape-design/components/container";
import Header from "@cloudscape-design/components/header";
import FormField from "@cloudscape-design/components/form-field";
import Input from "@cloudscape-design/components/input";
import {useNavigate} from "react-router-dom";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand } from "@aws-sdk/lib-dynamodb";
import { v4 as uuidv4 } from 'uuid';
import { fetchAuthSession } from 'aws-amplify/auth';

// Environment variables for table names
console.log('Environment variables:', {
  VITE_PATIENT_TABLE: import.meta.env.VITE_PATIENT_TABLE
});

// Get the table name from VITE_ prefix
const PATIENT_TABLE = import.meta.env.VITE_PATIENT_TABLE || "asclepiusMVP-Patient";
const AWS_REGION = import.meta.env.VITE_AWS_REGION || "us-east-1";

export function createPatient() {
  const navigate = useNavigate();
  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [dob, setDob] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");

    try {
      const session = await fetchAuthSession();
      const client = new DynamoDBClient({
        region: AWS_REGION,
        credentials: {
          accessKeyId: session.credentials.accessKeyId,
          secretAccessKey: session.credentials.secretAccessKey,
          sessionToken: session.credentials.sessionToken,
        },
      });

      const docClient = DynamoDBDocumentClient.from(client);

      const patientID = uuidv4(); // Generate a unique ID for the patient

      const command = new PutCommand({
        TableName: PATIENT_TABLE,
        Item: {
          patientID: patientID,
          firstName: firstName,
          lastName: lastName,
          dob: dob,
        },
      });

      await docClient.send(command);
      navigate('/'); // Navigate back to the patient list after successful submission

    } catch (err) {
      console.error("Error creating patient:", err);
      setError("Failed to create patient. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <Form
        actions={
          <SpaceBetween direction="horizontal" size="xs">
            <Button formAction="none" variant="link" onClick={() => navigate('/')}>
              Cancel
            </Button>
            <Button variant="primary" loading={loading} type="submit">
              Submit
            </Button>
          </SpaceBetween>
        }
        header={<Header variant="h1">New Patient Information</Header>}
        errorText={error}
      >
        <Container
        >
          <SpaceBetween direction="vertical" size="l">
          <FormField 
              label="First Name" 
              errorText={firstName.trim() === "" ? "First name is required" : undefined}
            >
              <Input
                value={firstName}
                onChange={({ detail }) => setFirstName(detail.value)}
              />
            </FormField>
            <FormField 
              label="Last Name"
              errorText={lastName.trim() === "" ? "Last name is required" : undefined}
            >
              <Input
                value={lastName}
                onChange={({ detail }) => setLastName(detail.value)}
              />
            </FormField>
            <FormField 
              label="Date of Birth (YYYY-MM-DD)"
              errorText={dob.trim() === "" ? "Date of birth is required" : undefined}
            >
              <Input
                value={dob}
                onChange={({ detail }) => setDob(detail.value)}
              />
            </FormField>
          </SpaceBetween>
        </Container>
      </Form>
    </form>
  );
}