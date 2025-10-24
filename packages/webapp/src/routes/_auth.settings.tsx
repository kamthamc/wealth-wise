/**
 * Settings route
 * Application settings and preferences
 */

import { createFileRoute } from '@tanstack/react-router';
import { SettingsPage } from '../features/settings';

export const Route = createFileRoute('/_auth/settings')({
  component: SettingsPage,
});
