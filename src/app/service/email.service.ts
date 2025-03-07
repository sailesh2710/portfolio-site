import { Injectable } from '@angular/core';
import { from, Observable } from 'rxjs';
import emailjs from 'emailjs-com';

@Injectable({
  providedIn: 'root'
})
export class EmailService {
  private serviceId = 'service_1i2lfdg'; // Your EmailJS Service ID
  private templateId = 'template_z7nbljc'; // Your EmailJS Template ID
  private userId = 'r9GfGTg30uWTtDPVe'; // Your EmailJS Public Key

  constructor() { }

  sendEmail(formData: any): Observable<any> {
    return from(
      emailjs.send(this.serviceId, this.templateId, formData, this.userId)
    );
  }
}