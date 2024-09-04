import clsx from 'clsx';
import Heading from '@theme/Heading';
import styles from './styles.module.css';

const FeatureList = [
  {
    title: 'Graph Database',
    description: (
      <>
        Create data. Connect data. Query data.
      </>
    ),
  },
  {
    title: 'Blockchain',
    description: (
      <>
        Decentralized. Secure. Immutable.
      </>
    ),
  },
  {
    title: 'Mobile+Web Staking',
    description: (
      <>
        Easy-to-use. Easy-to-access. Easy-to-earn.
      </>
    ),
  },
];

function Feature({ title, description }) {
  return (
    <div className={clsx('col col--4')}>
      <div className="text--center padding-horiz--md">
        <Heading as="h3">{title}</Heading>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function HomepageFeatures() {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
