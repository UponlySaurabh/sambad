import { Entity, PrimaryGeneratedColumn, Column, OneToMany } from 'typeorm';
import { Contact } from './Contact';
import { Message } from './Message';

@Entity()
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  username: string;

  @Column({ unique: true })
  phone: string;

  @Column()
  password: string;

  @OneToMany(() => Contact, contact => contact.user)
  contacts: Contact[];

  @OneToMany(() => Message, message => message.from)
  sentMessages: Message[];

  @OneToMany(() => Message, message => message.to)
  receivedMessages: Message[];
}
