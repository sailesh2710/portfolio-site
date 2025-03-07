import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-publications',
  standalone: true,
  templateUrl: './publications.component.html',
  styleUrls: ['./publications.component.css'],
  imports: [CommonModule]
})
export class PublicationsComponent {
  publications = [
    {
      title: 'Video chat using webRTC with in-built sign language detection',
      journal: 'IEEE ICUIS 2023',
      link: 'https://ieeexplore.ieee.org/document/10505950',
      publishedDate: 'April 2024'
    },
    {
      title: 'Passive RFID encryption and decryption using CLI',
      journal: 'IEEE I-SMAC 2023',
      link: 'https://ieeexplore.ieee.org/document/10290473',
      publishedDate: 'October 2023'
    },
    {
      title: 'Checking the Truthfulness of News Channels using NLP Techniques',
      journal: 'IEEE IC-RVITM 2023.',
      link: 'https://ieeexplore.ieee.org/document/10435241',
      publishedDate: 'February 2023'
    }
  ];
}