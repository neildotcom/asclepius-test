// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0
import React, { ReactNode, useState } from 'react';
import { createPortal } from 'react-dom';
import { Routes, Route, useNavigate } from 'react-router-dom';
import { Patient } from './pages/PatientDetail';
import { useLocation } from 'react-router-dom';
import { Authenticator } from '@aws-amplify/ui-react';
import { Amplify } from 'aws-amplify';
import outputs from '../amplify_outputs.json';
import '@aws-amplify/ui-react/styles.css';
import { useEffect } from 'react';
import { getAllPatients } from './services/patientService';
import Link from '@cloudscape-design/components/link';

import Box from '@cloudscape-design/components/box';
import BreadcrumbGroup from '@cloudscape-design/components/breadcrumb-group';
import Button from '@cloudscape-design/components/button';
import Header from '@cloudscape-design/components/header';
import SideNavigation, { SideNavigationProps } from '@cloudscape-design/components/side-navigation';
import SpaceBetween from '@cloudscape-design/components/space-between';
import Table, { TableProps } from '@cloudscape-design/components/table';
import TopNavigation from '@cloudscape-design/components/top-navigation';

import { isVisualRefresh } from './common/apply-mode';
import { CustomAppLayout } from './components/commons/common-components';
import asclepiusLogo from './assets/asclepiusLogo.png';
import { AuthHeader } from './components/auth/auth-header.tsx'

import './styles/base.scss';
import './styles/top-navigation.scss';
import './styles/auth.scss'
import { CreatePatient } from './pages/CreatePatient';
import { getCurrentUser } from 'aws-amplify/auth';
import { Visit } from './pages/VisitDetail.tsx';
import Wizard from './pages/Wizard.tsx';


const navItems: SideNavigationProps.Item[] = [
  {
    type: 'section',
    text: 'Manage',
    items: [
      { type: 'link', text: 'Patients', href: '/' },
    ],
  },
  {
    type: 'section',
    text: 'Set up',
    items: [
      { type: 'link', text: 'Database', href: '#/database' },
      { type: 'link', text: 'Authentication', href: '#/authentication' },
      { type: 'link', text: 'Analytics', href: '#/analytics' },
      { type: 'link', text: 'Predictions', href: '#/predictions' },
      { type: 'link', text: 'Interactions', href: '#/interactions' },
      { type: 'link', text: 'Notifications', href: '#/notifications' },
    ],
    defaultExpanded: false
  },
];

const patientNavItems: SideNavigationProps.Item[] = [
  {
    type: 'section',
    text: 'Manage',
    items: [
      { type: 'link', text: 'Home', href: '/' },
      { type: 'link', text: 'Care Plan', href: '#/patients' },
      { type: 'link', text: 'Risk Calculation', href: '#/patients' },
    ],
  },
];

const patientBreadcrumbs = [
  {
    text: 'Asclepius',
    href: '/',
  },
  {
    text: 'Patients',
    href: '/',
  },
  {
    text: 'Patient Detail',
    href: '/patient/:patientID',
  },
];

const visitBreadcrumbs = [
  {
    text: 'Asclepius',
    href: '/',
  },
  {
    text: 'Patients',
    href: '/',
  },
  {
    text: 'Visit Detail',
    href: '/visit/:visitID',
  },
];

const breadcrumbs = [
  {
    text: 'Asclepius',
    href: '/',
  },
  {
    text: 'Patients',
    href: '#',
  },
];

const i18nStrings = {
  searchIconAriaLabel: 'Search',
  searchDismissIconAriaLabel: 'Close search',
  overflowMenuTriggerText: 'More',
  overflowMenuTitleText: 'All',
  overflowMenuBackIconAriaLabel: 'Back',
  overflowMenuDismissIconAriaLabel: 'Close menu',
};

interface Item {
  patientID: string;
  firstName: string;
  lastName: string;
  dob: string;
}



const Content = () => {
  const navigate = useNavigate();
  const [patients, setPatients] = useState<Item[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedItems, setSelectedItems] = useState<Item[]>([]);

  const columnDefinitions: TableProps.ColumnDefinition<Item>[] = [
    {
      id: 'name',
      cell: item => (
        <Link 
          onFollow={() => navigate(`/patient/${item.patientID}`)}
          href={`/patient/${item.patientID}`}
        >
          {`${item.firstName} ${item.lastName}`}
        </Link>
      ),
      header: 'Name',
      minWidth: 100,
      isRowHeader: true,
    },
    {
      id: 'patientID',
      header: 'Patient ID',
      cell: item => item.patientID,
      minWidth: 80,
    },
    {
      id: 'dob',
      header: 'Date of Birth',
      cell: item => item.dob,
      minWidth: 80,
    },
  ];

  useEffect(() => {
    const fetchPatients = async () => {
      try {
        await getCurrentUser();
        const data = await getAllPatients();
        setPatients(data);
      } catch (error) {
        console.error("Failed to fetch patients:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchPatients();
  }, []);

  const handlePatientClick = (item: Item) => {
    navigate(`/patient/${item.patientID}`);
  };

  return (
    <Box padding={{ top: isVisualRefresh ? 's' : 'n' }}>
      <Table
        items={patients}
        columnDefinitions={columnDefinitions}
        loading={loading}
        loadingText='Loading patients'
        selectionType="single"
        selectedItems={selectedItems}
        onSelectionChange={({ detail }) => 
          setSelectedItems(detail.selectedItems)
        }
        onRowClick={({ detail }) => handlePatientClick(detail.item)}
        header={
          <Header
            variant="awsui-h1-sticky"
            counter={`(${patients.length})`}
            actions={
              <SpaceBetween size="xs" direction="horizontal">
                <Button variant="primary" onClick={() => navigate('/createPatient')}>Create patient profile</Button>
              </SpaceBetween>
            }
          >
            Patients
          </Header>
        }
        stickyHeader={true}
        empty={
          <Box margin={{ vertical: 'xs' }} textAlign="center" color="inherit">
            <SpaceBetween size="xxs">
              <div>
                <b>No patients</b>
                <Box variant="p" color="inherit">
                  You don't have any patients.
                </Box>
              </div>
              <Button onClick={() => navigate('/createPatient')}>Create patient profile</Button>
            </SpaceBetween>
          </Box>
        }
        enableKeyboardNavigation={true}
      />
    </Box>
  );
};

interface DemoHeaderPortalProps {
  children: ReactNode;
}

const DemoHeaderPortal = ({ children }: DemoHeaderPortalProps) => {
  const domNode = document.querySelector('#h')!;
  return createPortal(children, domNode);
};

Amplify.configure(outputs);

export function App() {
  const location = useLocation();
  const isPatientDetail = location.pathname.includes('/patient/');
  const isVisitDetail = location.pathname.includes('/visit/');
  const [searchValue, setSearchValue] = useState('');
  const [navigationOpen, setNavigationOpen] = useState(false);

  return (
    <Authenticator.Provider>
      
      <Authenticator
        className="custom-authenticator"
        variation="modal"
        components={{
          Header: AuthHeader
        }}>
        {({ signOut, user}) => (

        
      <>
        <DemoHeaderPortal>
          <TopNavigation
            i18nStrings={i18nStrings}
            identity={{
              href: '/',
              title: 'Asclepius',
              logo: {
                src: asclepiusLogo,
                alt: 'Asclepius Logo',
              },
            }}
            utilities={[{
              type: 'button',
              iconName: 'notification',
              ariaLabel: 'Notifications',
              badge: true,
              disableUtilityCollapse: true,
            },
            { type: 'button', iconName: 'settings', title: 'Settings', ariaLabel: 'Settings' },
            {
              type: 'menu-dropdown',
              text: 'Example User',
              description: 'customer@example.com',
              iconName: 'user-profile',
              items: [
                { id: 'profile', text: 'Profile' },
                { id: 'preferences', text: 'Preferences' },
                { id: 'security', text: 'Security' },
                {
                  id: 'support-group',
                  text: 'Support',
                  items: [
                    {
                      id: 'documentation',
                      text: 'Documentation',
                      href: '#',
                      external: true,
                      externalIconAriaLabel: ' (opens in new tab)',
                    },
                    { id: 'feedback', text: 'Feedback', href: '#', external: true, externalIconAriaLabel: ' (opens in new tab)' },
                    { id: 'support', text: 'Customer support' },
                  ],
                },
                { id: 'signout', text: 'Sign out'},
              ],
              onItemClick: (event) => {
                if (event.detail.id === 'signout') {
                  signOut();
                }
              }
            }
          ]}
          />
        </DemoHeaderPortal>
        <CustomAppLayout
          stickyNotifications
          toolsHide
          navigation={
            <SideNavigation 
              activeHref="#/pages" 
              items={isPatientDetail ? patientNavItems : navItems}
              header={{text: isPatientDetail ? "Patient" : "Home"}}
            />
          }
          navigationOpen={navigationOpen}
          onNavigationChange={({detail}) => setNavigationOpen(detail.open)}
          breadcrumbs={<BreadcrumbGroup 
            items={
              isPatientDetail 
                ? patientBreadcrumbs 
                : isVisitDetail 
                  ? visitBreadcrumbs 
                  : breadcrumbs
            } 
            expandAriaLabel="Show path" 
            ariaLabel="Breadcrumbs" />}
          content={
            <Routes>
              <Route path="/" element={<Content />} />
              <Route path="/patient/:patientID" element={<Patient />} />
              <Route path="/createPatient/" element={<CreatePatient />} /> 
              <Route path="/visit/:visitID" element={<Visit />} />
              <Route path="/patients/:patientID/new-visit" element={<Wizard></Wizard>} />
            </Routes>}
        />
      </>
      )}
      
      </Authenticator>
    </Authenticator.Provider>
  );
}