import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://eqkkkxjjyixtrwoutmkq.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVxa2treGpqeWl4dHJ3b3V0bWtxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMxNDkxMzgsImV4cCI6MjA5ODcyNTEzOH0.7QIx4jJkcrCIfMKHkL4wd4K5xoU4avIujqWabRyt7EQ';

export const supabase = createClient(supabaseUrl, supabaseAnonKey);
