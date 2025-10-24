import { createFileRoute } from '@tanstack/react-router';
import { Avatar, Button, Flex, Popover } from '@radix-ui/themes';
import '@radix-ui/themes/styles.css';
import { Outlet, redirect, useRouter } from '@tanstack/react-router';

import { useAuth } from '@/core/hooks/useAuth';

export const Route = createFileRoute('/_auth')({
  beforeLoad: ({ context, location }) => {
    if (!context.auth.isAuthenticated) {
      throw redirect({
        to: '/login',
        search: {
          redirect: location.href,
        },
      });
    }
  },
  component: AuthLayout,
});

function AuthLayout() {
  const router = useRouter();
  const navigate = Route.useNavigate();
  const auth = useAuth();

  const handleLogout = () => {
    if (window.confirm('Are you sure you want to logout?')) {
      auth.signOut().then(() => {
        router.invalidate().finally(() => {
          navigate({ to: '/' });
        });
      });
    }
  };

  return (
    <>
      <Popover.Root>
        <Flex justify="end">
          <Popover.Trigger>
            <Button variant="soft">
              <Avatar
                size="2"
                fallback={auth.user?.displayName?.at(0) ?? 'U'}
                radius="full"
              />
            </Button>
          </Popover.Trigger>
          <Popover.Content width="100px" minWidth="100px">
            <Flex gap="3">
              <Popover.Close>
                <Button size="2" onClick={handleLogout}>
                  Logout
                </Button>
              </Popover.Close>
            </Flex>
          </Popover.Content>
        </Flex>
      </Popover.Root>

      <Outlet />
    </>
  );
}
