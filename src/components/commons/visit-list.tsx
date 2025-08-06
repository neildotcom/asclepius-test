import * as React from "react";
import { useEffect } from "react";
import { useNavigate } from 'react-router-dom';
import { useState } from "react";
import Header from "@cloudscape-design/components/header";
import Table, { TableProps } from "@cloudscape-design/components/table";
import SpaceBetween from "@cloudscape-design/components/space-between";
import Button from "@cloudscape-design/components/button";
import Box from "@cloudscape-design/components/box";
import Link from '@cloudscape-design/components/link';
import { getCurrentUser } from 'aws-amplify/auth';
import { getAllVisits, getVisitsByPatientId } from "../../services/visitService";
import { isVisualRefresh } from '../../common/apply-mode';


interface Item {
    visitID: string;
    date: string;
    patientID: string;
    soapNote: string;
    summaryFile: string;
  }

interface VisitListContentProps {
    patientId?: string;
}

export function VisitListContent({ patientId }: VisitListContentProps) {
    const navigate = useNavigate();
    const [visits, setVisits] = useState<Item[]>([]);
    const [loading, setLoading] = useState(true);
    const [selectedItems, setSelectedItems] = useState<Item[]>([]);
  
    const columnDefinitions: TableProps.ColumnDefinition<Item>[] = [
      {
        id: 'name',
        cell: item => (
          <Link 
            onFollow={() => navigate(`/visit/${item.visitID}`)}
            href={`/visit/${item.visitID}`}
          >
            {`${item.date}`}
          </Link>
        ),
        header: 'Visit',
        minWidth: 100,
        isRowHeader: true,
      },
      {
        id: 'visitID',
        header: 'Visit ID',
        cell: item => item.visitID,
        minWidth: 80,
      },
    ];
  
    useEffect(() => {
      const fetchVisits = async () => { 
        try {
          await getCurrentUser();
          let data;
        if (patientId) {
        // If patientId is provided, fetch visits for that patient
        data = await getVisitsByPatientId(patientId);
        } else {
        // Otherwise, fetch all visits (existing behavior)
        data = await getAllVisits();
        }
          setVisits(data);
        } catch (error) {
          console.error("Failed to fetch visits:", error);
          // You might want to add error handling here
        } finally {
          setLoading(false);
        }
      };
  
      fetchVisits();
    }, [patientId]);
  
    const handleVisitClick = (item: Item) => {
      navigate(`/visit/${item.visitID}`);
    };
  
    return (
      <Box padding={{ top: isVisualRefresh ? 's' : 'n' }}>
        <Table
          items={visits}
          columnDefinitions={columnDefinitions}
          loading={loading}
          loadingText='Loading visits'
          selectionType="single"
          selectedItems={selectedItems}
          onSelectionChange={({ detail }) => 
            setSelectedItems(detail.selectedItems)
          }
          onRowClick={({ detail }) => handleVisitClick(detail.item)}
          header={
            <Header
              variant="h2"
              counter={`(${visits.length})`}
            //   actions={
            //     // <SpaceBetween size="xs" direction="horizontal">
            //     //   <Button disabled>View details</Button>
            //     //   <Button disabled>Edit</Button>
            //     //   <Button disabled>Delete</Button>
            //     //   <Button variant="primary" onClick={() => navigate('/createPatient')}>Create new visit</Button> 
            //     //   {/* might take the last line out */}
            //     // </SpaceBetween>
            //   }
            >
              {patientId ? 'Patient Visits' : 'All Visits'}
            </Header>
          }
          stickyHeader={true}
          empty={
            <Box margin={{ vertical: 'xs' }} textAlign="center" color="inherit">
              <SpaceBetween size="xxs">
                <div>
                  <b>No visits</b>
                  <Box variant="p" color="inherit">
                  {patientId ? 
                    "This patient has no previous visits." :
                    "No visits found."
                  }
                  </Box>
                </div>

              </SpaceBetween>
            </Box>
          }
          enableKeyboardNavigation={true}
        />
      </Box>
    );
  };