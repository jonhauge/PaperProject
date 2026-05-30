import '../models/author.dart';
import '../models/enums.dart';
import '../models/paper.dart';
import '../models/reference.dart';
import '../models/section.dart';

/// A small amount of demo content so the app is not empty on first launch.
Paper buildSamplePaper(DateTime now) {
  return Paper(
    id: 'sample-paper',
    title: 'Self-Hosted Peer Review over Git',
    abstractText:
        'We present PaperFlow, a tool that treats the manuscript as a set of '
        'plain files versioned in git, enabling transparent, reproducible peer '
        'review without a central platform.',
    keywords: const ['peer review', 'git', 'reproducibility'],
    status: PaperStatus.draft,
    authors: const [
      Author(
        id: 'author-1',
        name: 'Jon Hauge',
        email: 'jhh@jhh.dk',
        affiliation: 'Independent',
        role: UserRole.author,
      ),
    ],
    sections: const [
      Section(
        id: 'sec-intro',
        title: 'Introduction',
        fileName: 'introduction.md',
        order: 0,
        body:
            '# Introduction\n\nScientific publishing relies on peer review. '
            'In this work we explore using git as the substrate for the whole '
            'lifecycle.\n\n'
            '![System overview](assets/overview.png)\n\n'
            'See prior work [@smith2021] for context.',
      ),
      Section(
        id: 'sec-method',
        title: 'Method',
        fileName: 'method.md',
        order: 1,
        body:
            '# Method\n\nEach manuscript is a folder of markdown files plus an '
            '`assets/` directory for figures.',
      ),
    ],
    references: const [
      Reference(
        id: 'ref-1',
        citationKey: 'smith2021',
        title: 'On the Transparency of Scholarly Review',
        authors: 'Smith, J. and Doe, A.',
        venue: 'Journal of Open Science',
        year: 2021,
        doi: '10.0000/jos.2021.001',
      ),
    ],
    createdAt: now,
    updatedAt: now,
  );
}
