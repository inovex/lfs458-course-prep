# -*- coding: utf-8 -*-
from __future__ import print_function
import pickle
import os.path
from googleapiclient.discovery import build
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.image import MIMEImage
from email.message import Message
from email.mime.audio import MIMEAudio
from email.mime.base import MIMEBase
import base64
import mimetypes
from apiclient import errors
from httplib2 import Http
import yaml


# If modifying these scopes, delete the file token.pickle.
SCOPES = ['https://www.googleapis.com/auth/gmail.send']

def create_message_with_attachment(sender, to, subject, message_text, file):
  """Create a message for an email.

  Args:
    sender: Email address of the sender.
    to: Email address of the receiver.
    subject: The subject of the email message.
    message_text: The text of the email message.
    file: The path to the file to be attached.

  Returns:
    An object containing a base64url encoded email object.
  """
  message = MIMEMultipart()
  message['to'] = to
  message['from'] = sender
  message['subject'] = subject

  msg = MIMEText(message_text)
  message.attach(msg)

  content_type, encoding = mimetypes.guess_type(file)

  if content_type is None or encoding is not None:
    content_type = 'application/octet-stream'
  main_type, sub_type = content_type.split('/', 1)
  if main_type == 'text':
    fp = open(file, 'rb')
    msg = MIMEText(fp.read(), _subtype=sub_type)
    fp.close()
  elif main_type == 'image':
    fp = open(file, 'rb')
    msg = MIMEImage(fp.read(), _subtype=sub_type)
    fp.close()
  elif main_type == 'audio':
    fp = open(file, 'rb')
    msg = MIMEAudio(fp.read(), _subtype=sub_type)
    fp.close()
  else:
    fp = open(file, 'rb')
    msg = MIMEBase(main_type, sub_type)
    msg.set_payload(fp.read())
    fp.close()
  filename = os.path.basename(file)
  msg.add_header('Content-Disposition', 'attachment', filename=filename)
  message.attach(msg)

  message_as_bytes = message.as_bytes() # the message should converted from string to bytes.
  message_as_base64 = base64.urlsafe_b64encode(message_as_bytes) #encode in base64 (printable letters coding)
  raw = message_as_base64.decode()  # need to JSON serializable (no idea what does it means)
  return {'raw': raw}

  #return {'raw': base64.urlsafe_b64encode(message.as_string().encode())}


def send_message(service, user_id, message):
  """Send an email message.

  Args:
    service: Authorized Gmail API service instance.
    user_id: User's email address. The special value "me"
    can be used to indicate the authenticated user.
    message: Message to be sent.

  Returns:
    Sent Message.
  """
  try:
    message = (service.users().messages().send(userId=user_id, body=message)
               .execute())
    print('Message Id: {}'.format(message['id']))
    return message
  except errors.HttpError as error:
    print ("An error occurred: {}".format(error))

def main():
    """Shows basic usage of the Gmail API.
    Lists the user's Gmail labels.
    """
    creds = None
    # The file token.pickle stores the user's access and refresh tokens, and is
    # created automatically when the authorization flow completes for the first
    # time.
    if os.path.exists('token.pickle'):
        with open('token.pickle', 'rb') as token:
            creds = pickle.load(token)
    # If there are no (valid) credentials available, let the user log in.
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(
                'credentials.json', SCOPES)
            creds = flow.run_local_server(port=0)
        # Save the credentials for the next run
        with open('token.pickle', 'wb') as token:
            pickle.dump(creds, token)

    service = build('gmail', 'v1', credentials=creds)

    # Configure mail boilerplate
    mail_info = yaml.safe_load(open("mail_info.yaml"))
    attendees = mail_info["attendees"]
    sender = mail_info["sender"]
    subject =  mail_info["subject"]

    # Read Mail template
    text_template = ""
    with open("mail_template.txt") as temp:
      text_template = temp.read()

    for attendee in attendees:
        print("Send mail to: {}".format(attendee["Surname"]))
        msg = create_message_with_attachment(
          sender,
          attendee["Mail"],
          subject,
          text_template.format(**attendee),
          "../packages/{}.zip".format(attendee["Short"]))
        send_message(service, "me", msg)


if __name__ == '__main__':
    main()
