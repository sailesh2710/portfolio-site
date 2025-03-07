import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { EmailService } from '../../service/email.service';

@Component({
  selector: 'app-contact',
  standalone: true,
  templateUrl: './contact.component.html',
  imports: [CommonModule, ReactiveFormsModule]
})
export class ContactComponent implements OnInit {
  contactForm!: FormGroup;
  isMailSending: boolean = false;
  uploadMessage: string = '';
  isError: boolean = false;

  constructor(private fb: FormBuilder, private emailService: EmailService) { }

  ngOnInit(): void {
    this.contactForm = this.fb.group({
      name: ['', Validators.required],
      email: ['', [Validators.required, Validators.email]],
      message: ['', Validators.required]
    });
  }

  onSubmit(): void {
    if (this.contactForm.valid) {
      this.isMailSending = true;

      const formData = {
        name: this.contactForm.value.name,
        email: this.contactForm.value.email,
        message: this.contactForm.value.message
      };

      this.emailService.sendEmail(formData).subscribe({
        next: () => {
          this.uploadMessage = 'Message sent successfully!';
          this.isError = false;
          this.contactForm.reset();
        },
        error: () => {
          this.uploadMessage = 'Failed to send email. Please try again later.';
          this.isError = true;
        },
        complete: () => {
          this.isMailSending = false;
          setTimeout(() => {
            this.uploadMessage = '';
          }, 5000);
        }
      });
    }
  }
}