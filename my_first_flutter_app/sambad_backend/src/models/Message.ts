import { Entity, PrimaryGeneratedColumn, Column, ManyToOne } from 'typeorm';
import { User } from './User';

@Entity()
export class Message {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User, user => user.sentMessages)
  from: User;

  @ManyToOne(() => User, user => user.receivedMessages)
  to: User;

  @Column()
  content: string;

  @Column()
  timestamp: string;
}
