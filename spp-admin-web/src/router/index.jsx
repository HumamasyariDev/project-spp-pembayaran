import { createBrowserRouter, RouterProvider, Navigate } from 'react-router-dom';
import Login from '../pages/Auth/Login';
import Dashboard from '../pages/Dashboard/Dashboard';
import ContentManagement from '../pages/Content/ContentManagement';
import Students from '../pages/Students/Students';
import Classes from '../pages/Classes/Classes';
import Payments from '../pages/Payments/Payments';
import Reports from '../pages/Reports/Reports';

const router = createBrowserRouter([
  {
    path: '/login',
    element: <Login />,
  },
  {
    path: '/dashboard',
    element: <Dashboard />,
  },
  {
    path: '/students',
    element: <Students />,
  },
  {
    path: '/classes',
    element: <Classes />,
  },
  {
    path: '/payments',
    element: <Payments />,
  },
  {
    path: '/content',
    element: <ContentManagement />,
  },
  {
    path: '/reports',
    element: <Reports />,
  },
  {
    path: '/',
    element: <Navigate to="/login" replace />,
  },
]);

const AppRouter = () => {
  return <RouterProvider router={router} />;
};

export default AppRouter;
