import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-certifications',
  standalone: true,
  templateUrl: './certifications.component.html',
  styleUrls: ['./certifications.component.css'],
  imports: [CommonModule]  
})
export class CertificationsComponent {
  certifications = [
    {
      title: 'AWS Certified Solutions Architect - Associate',
      link: 'https://cp.certmetrics.com/amazon/en/public/verify/credential/b0330b662923452a8d4b054b1057d7de',
      issuedDate: 'March 2025'
    },
    {
      title: 'AWS Certified Cloud Practitioner Certification',
      link: 'https://cp.certmetrics.com/amazon/en/public/verify/credential/CZ7K59TK8M111SKF',
      issuedDate: 'June 2023'
    },
    {
        title: 'VMware IT Academy Modern Applications: Core Technical Skills',
        link: 'https://www.linkedin.com/in/sailesh2710/details/certifications/1635546718001/single-media-viewer/?profileId=ACoAADGFUioBpy9Yq1iOu0ZnMCPtTCIjusG1cI4',
        issuedDate: 'July 2023'
    },
    {
      title: 'Cloud Bootcamp - Sponsored by Google for Developers',
      link: 'https://media.geeksforgeeks.org/courses/certificates/9a2ce4941a1d4b3db47c9cb607b418cf.pdf',
      issuedDate: 'October 2023'
    }
  ];

  getCertificationLogo(title: string): string {
    if (title.includes('AWS')) return 'https://cdn.jsdelivr.net/npm/devicon@2.16.0/icons/amazonwebservices/amazonwebservices-original-wordmark.svg'; 
    if (title.includes('VMware')) return 'https://upload.wikimedia.org/wikipedia/commons/9/9a/Vmware.svg';
    if (title.includes('Google')) return 'https://cdn.jsdelivr.net/npm/devicon@2.16.0/icons/googlecloud/googlecloud-original.svg';
    return 'assets/default-cert.svg'; // Fallback logo
  }
}